#!/usr/bin/env python3
"""
Web Ranking Crawler - Amazon Product Crawler
Extracts product information from Amazon URLs and updates SQLite database
"""

import sys
import json
import sqlite3
import time
import re
import random
import urllib.request
import easyocr
import os
from datetime import datetime

# Suppress warnings and errors
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # Suppress TensorFlow warnings
os.environ['CUDA_VISIBLE_DEVICES'] = ''    # Disable GPU warnings

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

from multiprocessing import Pool, Lock
import requests
from bs4 import BeautifulSoup
from collections import deque
from crawl_locators import (
    TITLE,
    PRICE_PRIMARY,
    PRICE_FALLBACK,
    BRAND,
    RATINGS,
    STARS,
    IMAGE_WRAPPER_IMG,
    DETAIL_BULLETS_ITEMS,
    DETAILS_TABLE_ROWS,
    CAPTCHA_KEYWORDS,
)
from db_utils import DatabaseManager

FALLBACK_USER_AGENTS = [
    # Kept as a safe fallback if dynamic generator fails
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:115.0) Gecko/20100101 Firefox/115.0",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/120.0.0.0 Mobile/15E148 Safari/604.1",
]

# Dynamic user-agent provider (fake-useragent)
ua_provider = None
try:
    from fake_useragent import UserAgent  # type: ignore
    # Use external data when possible, be tolerant of SSL
    ua_provider = UserAgent(use_external_data=True, verify_ssl=False)
except Exception as _e:
    ua_provider = None


def get_random_user_agent():
    """Return a random user-agent string using fake-useragent with fallback."""
    if ua_provider is not None:
        try:
            # Prefer realistic Chrome-like UA to reduce blocks; fallback to .random
            return ua_provider.chrome
        except Exception:
            try:
                return ua_provider.random
            except Exception:
                pass
    return random.choice(FALLBACK_USER_AGENTS)

class AmazonProductCrawler:
    def __init__(self, db_path=None):
        # Determine database path (align with Node app: data/database/database.db)
        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            repo_root = os.path.abspath(os.path.join(script_dir, '..'))
        except Exception:
            repo_root = os.getcwd()

        default_db_path = os.path.join(repo_root, 'data', 'database', 'database.db')
        db_path_env = os.environ.get('DB_PATH')
        self.db_path = db_path_env if db_path_env else (db_path if db_path else default_db_path)

        # Ensure database directory exists
        try:
            os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        except Exception:
            pass
        # Suppress EasyOCR warnings
        import warnings
        warnings.filterwarnings("ignore", category=UserWarning)
        
        # Initialize EasyOCR with quiet mode
        try:
            self.reader = easyocr.Reader(['en'], gpu=False, verbose=False)
        except Exception as e:
            print(f"EasyOCR initialization warning: {e}")
            self.reader = None
        self.lock = Lock()
        # Database manager (centralized DB operations)
        self.db_manager = DatabaseManager(self.db_path)
        
        # Crawling behavior configuration
        self.engine = (os.environ.get('CRAWL_ENGINE', 'requests') or 'requests').lower()
        self.allow_selenium_fallback = (os.environ.get('ALLOW_SELENIUM_FALLBACK', 'false') or 'false').lower() in ('1', 'true', 'yes')
        try:
            self.requests_attempts = max(1, int(os.environ.get('REQUESTS_ATTEMPTS', '6')))
        except Exception:
            self.requests_attempts = 6
        try:
            self.selenium_attempts = max(0, int(os.environ.get('SELENIUM_ATTEMPTS', '1')))
        except Exception:
            self.selenium_attempts = 0
        try:
            self.crawl_delay_ms = max(0, int(os.environ.get('CRAWL_DELAY_MS', '200')))
        except Exception:
            self.crawl_delay_ms = 200
        try:
            self.max_url_retries = max(0, int(os.environ.get('MAX_URL_RETRIES', '10')))
        except Exception:
            self.max_url_retries = 10
        
        # Reusable HTTP session for performance
        try:
            self.http = requests.Session()
        except Exception:
            self.http = None
        
    def is_captcha_content(self, text: str) -> bool:
        """Detect if the page content looks like an Amazon CAPTCHA/robot check."""
        try:
            t = (text or "").lower()
            return any(kw in t for kw in CAPTCHA_KEYWORDS)
        except Exception:
            return False

    def connect_db(self):
        """Connect to SQLite database"""
        try:
            # Initialize tables via DatabaseManager (connection handled per operation)
            self.db_manager.init_tables()
            return True
        except Exception as e:
            print(f"Database connection error: {e}")
            return False

    def init_tables(self):
        """Create tables if they do not exist to avoid 'no such table' errors"""
        # products table
        self.cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                price REAL,
                rank INTEGER,
                asin TEXT UNIQUE,
                brand TEXT,
                ratings TEXT,
                stars TEXT,
                image_url TEXT,
                date TEXT,
                url TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        # Attempt to add 'date' column if missing (ignore if exists)
        try:
            self.cursor.execute("ALTER TABLE products ADD COLUMN date TEXT")
        except Exception:
            pass

        # rank_history table
        self.cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS rank_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                asin TEXT NOT NULL,
                rank INTEGER NOT NULL,
                price REAL,
                recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

        # url_lists table
        self.cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS url_lists (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                urls TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

        # settings table
        self.cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT UNIQUE NOT NULL,
                value TEXT NOT NULL,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

        # default crawl_interval if not exists
        self.cursor.execute(
            """
            INSERT OR IGNORE INTO settings (key, value) VALUES ('crawl_interval', '2')
            """
        )
        self.conn.commit()

    # OCR-based captcha solving removed per configuration; instead we rotate UA and retry

    def extract_product_data_selenium(self, driver, url):
        """Extract product information from Amazon page using Selenium"""
        try:
            driver.get(url)
            # If CAPTCHA is detected, signal caller to retry with a different UA
            if self.is_captcha_content(driver.page_source):
                raise Exception("Captcha detected")
            
            # Check for "Sorry! We couldn't find that page" error
            page_text = driver.page_source.lower()
            if "sorry! we couldn't find that page" in page_text or "page not found" in page_text:
                print(f"Product not found: {url}")
                return {
                    'title': 'Product Not Found',
                    'price': 'N/A',
                    'rank': 'N/A',
                    'asin': 'N/A',
                    'brand': 'N/A',
                    'ratings': 'N/A',
                    'stars': 'N/A',
                    'image_url': 'N/A',
                    'url': url,
                    'error': 'Product not found on Amazon'
                }

            asin = date = rank = title = image_url = price = brand = ratings = stars = "Not found"

            try:
                asin = driver.find_element(By.CSS_SELECTOR,
                                           "#detailBullets_feature_div > ul > li:nth-child(5) > span > span:nth-child(2)").text
            except:
                pass

            try:
                # Parse details table rows for date using configured locator
                date = "Not found"
                rows = driver.find_elements(By.CSS_SELECTOR, DETAILS_TABLE_ROWS)
                for row in rows:
                    try:
                        th = row.find_element(By.TAG_NAME, 'th').text.strip()
                        if 'Date First Available' in th or 'First Available' in th or 'Date' in th:
                            date = row.find_element(By.TAG_NAME, 'td').text.strip()
                            break
                    except Exception:
                        continue
                # Fallback: parse bullets list items
                if date == "Not found":
                    bullets = driver.find_elements(By.CSS_SELECTOR, DETAIL_BULLETS_ITEMS)
                    for li in bullets:
                        text = li.text
                        if 'Date First Available' in text or 'First Available' in text or 'Date' in text:
                            parts = text.split(':', 1)
                            if len(parts) == 2:
                                date = parts[1].strip()
                                break
            except Exception:
                pass

            try:
                details = driver.find_elements(By.CSS_SELECTOR, DETAIL_BULLETS_ITEMS)
                for item in details:
                    text = item.text
                    if "Best Sellers Rank" in text and "#" in text:
                        try:
                            rank_text = text.split("#", 1)[1].split(" ")[0]
                            rank = rank_text.replace(",", "")
                            break
                        except Exception:
                            continue
            except Exception:
                pass
                
        except Exception as e:
            print(f"Error processing URL {url}: {e}")
            return {
                'title': 'Error Processing',
                'price': 'N/A',
                'rank': 'N/A',
                'asin': 'N/A',
                'brand': 'N/A',
                'ratings': 'N/A',
                'stars': 'N/A',
                'image_url': 'N/A',
                'url': url,
                'error': f'Processing error: {str(e)}'
            }

        try:
            title = driver.find_element(By.ID, TITLE.replace('#','')).text.strip()
        except:
            pass

        try:
            # Use wrapper img src directly (configured locator)
            img_el = driver.find_element(By.CSS_SELECTOR, IMAGE_WRAPPER_IMG)
            image_url = img_el.get_attribute("src")
        except Exception:
            # Fallback to legacy locator by id
            try:
                image = driver.find_element(By.ID, "landingImage")
                image_url = image.get_attribute("src")
            except Exception:
                pass

        # Extract price
        try:
            price_element = driver.find_element(By.CSS_SELECTOR, PRICE_FALLBACK)
            price = price_element.text.replace(",", "")
        except:
            try:
                price_element = driver.find_element(By.CSS_SELECTOR, PRICE_PRIMARY)
                price = price_element.text.replace("$", "").replace(",", "")
            except:
                pass

        # Extract brand
        try:
            brand = driver.find_element(By.CSS_SELECTOR, BRAND).text.strip()
        except:
            pass

        # Extract ratings
        try:
            ratings_element = driver.find_element(By.CSS_SELECTOR, RATINGS)
            ratings = ratings_element.text.split(" ")[0]
        except:
            pass

        # Extract star rating
        try:
            stars_element = driver.find_element(By.CSS_SELECTOR, STARS)
            stars_text = stars_element.get_attribute("innerHTML")
            if "out of 5 stars" in stars_text:
                stars = stars_text.split(" out of 5 stars")[0]
        except:
            pass

        return {
            'asin': asin,
            'date': date,
            'rank': rank,
            'title': title,
            'image_url': image_url,
            'price': price,
            'brand': brand,
            'ratings': ratings,
            'stars': stars,
            'url': url
        }

    def extract_product_data_requests(self, url):
        """Extract product information using requests (fallback method)"""
        print(f"Using requests fallback for: {url}")
        # Try with a few different user agents to bypass simple blocks
        attempts = self.requests_attempts if hasattr(self, 'requests_attempts') else 3
        for attempt in range(attempts):
            user_agent = get_random_user_agent()
            headers = {
                'User-Agent': user_agent,
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.5',
                'Accept-Encoding': 'gzip, deflate',
                'Connection': 'keep-alive',
                'DNT': '1',
                'Upgrade-Insecure-Requests': '1',
            }
            try:
                if self.http is not None:
                    response = self.http.get(url, headers=headers, timeout=10)
                else:
                    response = requests.get(url, headers=headers, timeout=10)
                response.raise_for_status()

                lower_text = response.text.lower()
                # Product not found
                if "sorry! we couldn't find that page" in lower_text or "page not found" in lower_text:
                    print(f"Product not found (requests): {url}")
                    return {
                        'asin': 'N/A',
                        'date': 'N/A',
                        'rank': 'N/A',
                        'title': 'Product Not Found',
                        'image_url': 'N/A',
                        'price': 'N/A',
                        'brand': 'N/A',
                        'ratings': 'N/A',
                        'stars': 'N/A',
                        'url': url,
                        'error': 'Product not found on Amazon'
                    }

                # Captcha detected -> retry with a different UA
                if self.is_captcha_content(lower_text):
                    print("Requests fallback: captcha detected, rotating user-agent and retrying...")
                    time.sleep(random.uniform(0.5, 1.2))
                    continue

                soup = BeautifulSoup(response.text, 'html.parser')

                # Base fields
                title = soup.select_one(TITLE) or soup.find('title')
                title_text = title.get_text(strip=True) if title else "Product from Amazon"

                asin = url.split('/dp/')[-1].split('?')[0] if '/dp/' in url else 'Not found'

                product_data = {
                    'asin': asin,
                    'date': 'Not found',
                    'rank': 'Not found',
                    'title': title_text,
                    'image_url': 'Not found',
                    'price': 'Not found',
                    'brand': 'Amazon',
                    'ratings': 'Not found',
                    'stars': 'Not found',
                    'url': url,
                }

                # Title (prefer explicit span)
                t = soup.select_one(TITLE)
                if t:
                    product_data['title'] = t.get_text(strip=True)

                # Price (primary then fallback)
                p = soup.select_one(PRICE_PRIMARY)
                if p and p.get_text(strip=True):
                    product_data['price'] = p.get_text(strip=True).replace('$', '').replace(',', '')
                else:
                    p2 = soup.select_one(PRICE_FALLBACK)
                    if p2:
                        product_data['price'] = p2.get_text(strip=True).replace(',', '')

                # Brand
                b = soup.select_one(BRAND)
                if b:
                    product_data['brand'] = b.get_text(strip=True)

                # Ratings count
                rc = soup.select_one(RATINGS)
                if rc:
                    txt = rc.get_text(strip=True)
                    m = re.search(r'([\d,]+)', txt)
                    if m:
                        product_data['ratings'] = m.group(1).replace(',', '')

                # Stars
                st = soup.select_one(STARS)
                if st:
                    txt = st.get_text(strip=True)
                    m = re.search(r'([0-9.]+)\s+out of 5', txt)
                    if m:
                        product_data['stars'] = m.group(1)

                # Image (wrapper img, og:image, landingImage, or dynamic JSON)
                img = soup.select_one(IMAGE_WRAPPER_IMG)
                if img and img.get('src'):
                    product_data['image_url'] = img['src']
                else:
                    og_img = soup.find('meta', attrs={'property': 'og:image'}) or soup.find('meta', attrs={'name': 'og:image'})
                    if og_img and og_img.get('content'):
                        product_data['image_url'] = og_img['content']
                    else:
                        landing_img = soup.find('img', id='landingImage')
                        if landing_img and landing_img.get('src'):
                            product_data['image_url'] = landing_img['src']
                        elif landing_img and landing_img.get('data-a-dynamic-image'):
                            try:
                                dyn = landing_img.get('data-a-dynamic-image').replace('&quot;', '"')
                                images_map = json.loads(dyn)
                                best_url = None
                                best_area = -1
                                for u, size in images_map.items():
                                    try:
                                        area = int(size[0]) * int(size[1])
                                    except Exception:
                                        area = 0
                                    if area > best_area:
                                        best_area = area
                                        best_url = u
                                if best_url:
                                    product_data['image_url'] = best_url
                            except Exception:
                                pass

                # Rank (parse bullets)
                for li in soup.select(DETAIL_BULLETS_ITEMS) or []:
                    text = li.get_text(" ", strip=True)
                    if 'Best Sellers Rank' in text:
                        m = re.search(r'#([\d,]+)', text)
                        if m:
                            product_data['rank'] = m.group(1).replace(',', '')
                            break

                # Date First Available (details table)
                found_date = False
                for tr in soup.select(DETAILS_TABLE_ROWS) or []:
                    th = tr.find('th')
                    td = tr.find('td')
                    if th and td and any(k in th.get_text(strip=True) for k in ['Date First Available', 'First Available', 'Date']):
                        product_data['date'] = td.get_text(strip=True)
                        found_date = True
                        break
                # Fallback: detail bullets
                if not found_date:
                    for li in soup.select(DETAIL_BULLETS_ITEMS) or []:
                        text = li.get_text(' ', strip=True)
                        if any(k in text for k in ['Date First Available', 'First Available', 'Date']):
                            parts = text.split(':', 1)
                            if len(parts) == 2:
                                product_data['date'] = parts[1].strip()
                                break

                # If image still missing, rotate UA and retry next attempt
                if product_data['image_url'] in ['Not found', 'N/A', None, '']:
                    print('Requests fallback: image not found, rotating user-agent and retrying...')
                    time.sleep(random.uniform(0.5, 1.5))
                    continue

                return product_data

            except Exception as e:
                print(f"Requests fallback attempt {attempt+1} failed: {e}")
                time.sleep(random.uniform(0.5, 1.5))

        # If still blocked
        return {
            'asin': 'N/A',
            'date': 'N/A',
            'rank': 'N/A',
            'title': 'Error Processing',
            'image_url': 'N/A',
            'price': 'N/A',
            'brand': 'N/A',
            'ratings': 'N/A',
            'stars': 'N/A',
            'url': url,
            'error': 'Processing error: blocked by captcha (requests)'
        }

    def process_single_url(self, url):
        """Process a single URL and return product data, preferring fast BeautifulSoup path."""
        print(f"Processing: {url}")

        engine = self.engine
        if engine not in ('requests', 'selenium', 'auto'):
            engine = 'requests'

        # Fast path: requests/BeautifulSoup first
        if engine in ('requests', 'auto'):
            data = self.extract_product_data_requests(url)
            # If auto mode and explicitly blocked, optionally fallback to Selenium
            if engine == 'auto' and 'error' in data and 'captcha' in str(data['error']).lower() and self.allow_selenium_fallback:
                pass  # will try selenium below
            else:
                return data

        # Selenium path (disabled by default for speed; attempts default to 0)
        attempts = self.selenium_attempts
        for attempt in range(1, attempts + 1):
            user_agent = get_random_user_agent()
            print(f"[Selenium Attempt {attempt}/{attempts}] Using UA: {user_agent[:40]}...")
            try:
                options = webdriver.ChromeOptions()
                options.add_argument(f"--user-agent={user_agent}")
                options.add_argument("--headless=new")  # headless
                options.add_argument("--no-sandbox")
                options.add_argument("--disable-dev-shm-usage")
                options.add_argument("--disable-blink-features=AutomationControlled")
                options.add_argument("--log-level=3")
                options.add_experimental_option("excludeSwitches", ["enable-automation", "enable-logging"])
                options.add_experimental_option('useAutomationExtension', False)

                try:
                    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
                except Exception as e:
                    print(f"Chrome WebDriver error: {e}")
                    driver = webdriver.Chrome(options=options)

                try:
                    product_data = self.extract_product_data_selenium(driver, url)
                    print(f"Selenium extracted: {product_data['title'][:50]}...")
                    # If image is missing, force retry with next attempt/UA
                    if product_data.get('image_url') in ['Not found', 'N/A', None, '']:
                        raise Exception('image not found')
                    driver.quit()
                    return product_data
                except Exception as e:
                    print(f"Selenium attempt {attempt} failed: {e}")
                    time.sleep(random.uniform(0.6, 1.2))
                finally:
                    try:
                        driver.quit()
                    except Exception:
                        pass
            except Exception as e:
                print(f"Selenium setup failed on attempt {attempt}: {e}")
                time.sleep(random.uniform(0.6, 1.0))

        # If we get here, either engine was 'selenium' with failures or 'auto' fallback failed
        return {
            'asin': 'N/A',
            'date': 'N/A',
            'rank': 'N/A',
            'title': 'Error Processing',
            'image_url': 'N/A',
            'price': 'N/A',
            'brand': 'N/A',
            'ratings': 'N/A',
            'stars': 'N/A',
            'url': url,
            'error': 'Processing error after retries'
        }

    def update_database(self, product_data):
        """Insert or update product in database with rank history via DatabaseManager"""
        try:
            if 'error' in product_data:
                print(f"Skipping database update for error case: {product_data['error']}")
                return False

            asin = product_data['asin']
            current_rank = None if product_data['rank'] in ['Not found', 'N/A'] else product_data['rank']
            current_price = None if product_data['price'] in ['Not found', 'N/A'] else product_data['price']

            existing = self.db_manager.get_product_by_asin(asin)
            if existing:
                old_rank = existing[1]
                self.db_manager.update_product(asin, product_data)
                print(f"Updated product: {product_data['title'][:50]}...")
                if current_rank and old_rank and current_rank != old_rank:
                    self.db_manager.add_rank_history(asin, current_rank, current_price)
                    print(f"Rank history updated: {old_rank} -> {current_rank}")
                self.db_manager.cleanup_rank_history(asin)
            else:
                self.db_manager.create_product(product_data)
                print(f"Added new product: {product_data['title'][:50]}...")
                if current_rank:
                    self.db_manager.add_rank_history(asin, current_rank, current_price)
                    print(f"Initial rank history added: {current_rank}")

            return True
        except Exception as e:
            print(f"Database error: {e}")
            return False

    def crawl_urls(self, urls):
        """Crawl multiple URLs and update database immediately"""
        if not self.connect_db():
            return False
        
        # Deduplicate while preserving order
        seen = set()
        unique_urls = []
        for u in urls:
            if u not in seen:
                seen.add(u)
                unique_urls.append(u)

        # Build retry queue
        queue = deque({ 'url': u, 'attempts': 0 } for u in unique_urls)
        success_count = 0
        total_count = len(unique_urls)
        
        print(f"Starting to crawl {total_count} Amazon URLs...")
        
        i = 0
        while queue:
            item = queue.popleft()
            url = item['url']
            attempts = item['attempts']
            i += 1
            print(f"Progress: {i}/{total_count}")

            product_data = self.process_single_url(url)
            if product_data:
                if 'error' in product_data:
                    print(f"Product {i}/{total_count} error: {product_data['error']}")
                    # Requeue on error if attempts remain
                    if attempts < self.max_url_retries:
                        print(f"Requeue URL (attempt {attempts+1}/{self.max_url_retries}): {url}")
                        queue.append({ 'url': url, 'attempts': attempts + 1 })
                elif product_data['title'] not in ['Product Not Found', 'Error Processing']:
                    # Only update database if product was successfully crawled
                    if self.update_database(product_data):
                        success_count += 1
                        print(f"Product {i}/{total_count} added to database successfully")
                        # Flush one-line JSON status to stdout so Node can stream it to UI
                        try:
                            print(json.dumps({
                                'type': 'progress',
                                'index': i,
                                'total': total_count,
                                'asin': product_data.get('asin'),
                                'url': product_data.get('url'),
                                'status': 'updated'
                            }), flush=True)
                        except Exception:
                            pass
                    else:
                        print(f"Failed to add product {i}/{total_count} to database")
                        if attempts < self.max_url_retries:
                            print(f"Requeue URL (attempt {attempts+1}/{self.max_url_retries}): {url}")
                            queue.append({ 'url': url, 'attempts': attempts + 1 })
                else:
                    print(f"Product {i}/{total_count} skipped - not found or error")
                    if attempts < self.max_url_retries:
                        print(f"Requeue URL (attempt {attempts+1}/{self.max_url_retries}): {url}")
                        queue.append({ 'url': url, 'attempts': attempts + 1 })
            else:
                print(f"Failed to crawl product {i}/{total_count}")
                if attempts < self.max_url_retries:
                    print(f"Requeue URL (attempt {attempts+1}/{self.max_url_retries}): {url}")
                    queue.append({ 'url': url, 'attempts': attempts + 1 })
            
            # Small delay with configuration
            if self.crawl_delay_ms > 0:
                time.sleep(self.crawl_delay_ms / 1000.0)
        
        print(f"Crawling completed. Successfully processed {success_count}/{total_count} URLs.")
        return success_count > 0

def main():
    """Main function to handle input and start crawling"""
    try:
        # Ensure stdout/stderr use UTF-8 to avoid Windows encoding issues
        try:
            if hasattr(sys.stdout, 'reconfigure'):
                sys.stdout.reconfigure(encoding='utf-8', errors='replace')
            if hasattr(sys.stderr, 'reconfigure'):
                sys.stderr.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

        # Read URLs from stdin (sent by Node.js)
        urls_json = sys.stdin.read()
        urls = json.loads(urls_json)
        
        if not urls or not isinstance(urls, list):
            print("Error: Invalid URLs input")
            sys.exit(1)
        
        # Create crawler and start crawling
        crawler = AmazonProductCrawler()
        success = crawler.crawl_urls(urls)
        
        if success:
            print("Amazon crawling completed successfully!")
            sys.exit(0)
        else:
            print("Amazon crawling failed!")
            sys.exit(1)
            
    except json.JSONDecodeError:
        print("Error: Invalid JSON input")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 