#!/usr/bin/env python3
"""
Web Ranking Crawler - Amazon Product Crawler
Extracts product information from Amazon URLs and updates SQLite database
"""

import sys
import json
import sqlite3
import time
import urllib.request
import easyocr
import os
from datetime import datetime
from fake_useragent import UserAgent

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

ua = UserAgent()


def get_random_user_agent():
    """Return a random user-agent string using fake-useragent."""
    try:
        return ua.random
    except Exception:
        return (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )

class AmazonProductCrawler:
    def __init__(self, db_path='database.db'):
        self.db_path = db_path
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
        
    def connect_db(self):
        """Connect to SQLite database"""
        try:
            self.conn = sqlite3.connect(self.db_path)
            self.cursor = self.conn.cursor()
            return True
        except Exception as e:
            print(f"Database connection error: {e}")
            return False

    def ocrImageEasyOCR(self, url):
        """Extract text from image using EasyOCR"""
        try:
            if self.reader is None:
                return ""
            urllib.request.urlretrieve(url, "temp.jpg")
            result = self.reader.readtext("temp.jpg", detail=0)
            return ''.join(result).strip()
        except Exception as e:
            print(f"OCR error: {e}")
            return ""

    def tryPassCaptcha(self, driver):
        """Handle Amazon captcha using OCR"""
        try:
            WebDriverWait(driver, 5).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "i.a-icon.a-icon-alert"))
            )
            captcha_img = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "div.a-row.a-text-center img"))
            )
            captcha_url = captcha_img.get_attribute("src")
            text = self.ocrImageEasyOCR(captcha_url)
            textfield = driver.find_element(By.ID, "captchacharacters")
            textfield.send_keys(text + Keys.ENTER)
            print("Captcha solved:", text)
            time.sleep(3)
        except:
            print("No captcha detected.")

    def extract_product_data_selenium(self, driver, url):
        """Extract product information from Amazon page using Selenium"""
        try:
            driver.get(url)
            self.tryPassCaptcha(driver)
            
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
                # Try multiple CSS selectors for date
                date_selectors = [
                    "#detailBullets_feature_div > ul > li:nth-child(3) > span > span:nth-child(2)",
                    "#detailBullets_feature_div ul li span.a-list-item span",
                    "#detailBullets_feature_div ul li:contains('Date') span",
                    "span[data-csa-c-type='detail-bullets'] ul li span",
                    "#detailBullets_feature_div ul li span.a-text-bold + span"
                ]
                
                date = "Not found"
                for selector in date_selectors:
                    try:
                        elements = driver.find_elements(By.CSS_SELECTOR, selector)
                        for element in elements:
                            text = element.text.strip()
                            if text and len(text) > 0 and text != "Not found":
                                # Check if it looks like a date
                                if any(char.isdigit() for char in text):
                                    date = text
                                    print(f"Found date: {date}")
                                    break
                        if date != "Not found":
                            break
                    except:
                        continue
                        
                # Also try to find date in product details
                if date == "Not found":
                    try:
                        detail_elements = driver.find_elements(By.CSS_SELECTOR, "#detailBullets_feature_div ul li")
                        for element in detail_elements:
                            text = element.text.lower()
                            if "date" in text or "published" in text or "release" in text:
                                # Extract the date part
                                date_text = element.text
                                if ":" in date_text:
                                    date = date_text.split(":")[-1].strip()
                                    print(f"Found date in details: {date}")
                                    break
                    except:
                        pass
                        
            except Exception as e:
                print(f"Error extracting date: {e}")
                date = "Not found"

            try:
                details = driver.find_elements(By.XPATH, '//*[@id="detailBulletsWrapper_feature_div"]//li')
                for item in details:
                    if "Best Sellers Rank" in item.text:
                        rank_text = item.text.split("#")[1].split(" ")[0]
                        rank = rank_text.replace(",", "")
                        break
            except:
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
            title = driver.find_element(By.ID, "productTitle").text.strip()
        except:
            pass

        try:
            image = driver.find_element(By.ID, "landingImage")
            image_url = image.get_attribute("src")
        except:
            pass

        # Extract price
        try:
            price_element = driver.find_element(By.CSS_SELECTOR, "span.a-price-whole")
            price = price_element.text.replace(",", "")
        except:
            try:
                price_element = driver.find_element(By.CSS_SELECTOR, "span.a-price.a-text-price span.a-offscreen")
                price = price_element.text.replace("$", "").replace(",", "")
            except:
                pass

        # Extract brand
        try:
            brand = driver.find_element(By.CSS_SELECTOR, "a#bylineInfo").text.strip()
        except:
            pass

        # Extract ratings
        try:
            ratings_element = driver.find_element(By.CSS_SELECTOR, "span#acrCustomerReviewText")
            ratings = ratings_element.text.split(" ")[0]
        except:
            pass

        # Extract star rating
        try:
            stars_element = driver.find_element(By.CSS_SELECTOR, "span.a-icon-alt")
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
        user_agent = get_random_user_agent()
        headers = {
            'User-Agent': user_agent,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        }
        
        try:
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            # Check for "Sorry! We couldn't find that page" error
            if "sorry! we couldn't find that page" in response.text.lower() or "page not found" in response.text.lower():
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
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extract basic info
            title = soup.find('title')
            title_text = title.text.strip() if title else "Product from Amazon"
            
            # Try to extract ASIN from URL
            asin = url.split('/dp/')[-1].split('?')[0] if '/dp/' in url else "Not found"
            
            # Create basic product data
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
                'url': url
            }
            
            # Try to extract more data if available
            try:
                product_title = soup.find('span', {'id': 'productTitle'})
                if product_title:
                    product_data['title'] = product_title.text.strip()
            except:
                pass
                
            try:
                price_element = soup.find('span', {'class': 'a-price-whole'})
                if price_element:
                    product_data['price'] = price_element.text.replace(',', '')
            except:
                pass
                
            return product_data
            
        except Exception as e:
            print(f"Requests fallback failed: {e}")
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
                'error': f'Processing error: {str(e)}'
            }

    def process_single_url(self, url):
        """Process a single URL and return product data"""
        print(f"Processing: {url}")
        user_agent = get_random_user_agent()

        # Try Selenium first
        try:
            options = webdriver.ChromeOptions()
            options.add_argument(f"--user-agent={user_agent}")
            options.add_argument("--headless=new")  # Enable headless mode
            options.add_argument("--no-sandbox")
            options.add_argument("--disable-dev-shm-usage")
            options.add_argument("--disable-blink-features=AutomationControlled")
            options.add_argument("--disable-logging")
            options.add_argument("--disable-dev-tools")
            options.add_argument("--disable-extensions")
            options.add_argument("--disable-plugins")
            options.add_argument("--disable-images")
            options.add_argument("--disable-javascript")
            options.add_argument("--disable-web-security")
            options.add_argument("--disable-features=VizDisplayCompositor")
            options.add_argument("--log-level=3")
            options.add_experimental_option("excludeSwitches", ["enable-automation", "enable-logging"])
            options.add_experimental_option('useAutomationExtension', False)
            
            try:
                driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
            except Exception as e:
                print(f"Chrome WebDriver error: {e}")
                # Try alternative approach
                from selenium.webdriver.chrome.service import Service as ChromeService
                driver = webdriver.Chrome(options=options)
                
            driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

            try:
                product_data = self.extract_product_data_selenium(driver, url)
                print(f"Selenium extracted: {product_data['title'][:50]}...")
                return product_data
            except Exception as e:
                print(f"Selenium failed: {e}")
                return self.extract_product_data_requests(url)
            finally:
                driver.quit()
                
        except Exception as e:
            print(f"Selenium setup failed: {e}")
            print("Falling back to requests method...")
            return self.extract_product_data_requests(url)

    def update_database(self, product_data):
        """Insert or update product in database with rank history"""
        try:
            # Handle error cases - don't save to database
            if 'error' in product_data:
                print(f"Skipping database update for error case: {product_data['error']}")
                return False
                
            # Check if product already exists by ASIN
            self.cursor.execute(
                "SELECT id, rank FROM products WHERE asin = ?",
                (product_data['asin'],)
            )
            existing_product = self.cursor.fetchone()
            
            current_rank = product_data['rank'] if product_data['rank'] not in ['Not found', 'N/A'] else None
            current_price = product_data['price'] if product_data['price'] not in ['Not found', 'N/A'] else None
            
            if existing_product:
                old_rank = existing_product[1]
                
                # Update existing product
                self.cursor.execute("""
                    UPDATE products 
                    SET name = ?, price = ?, rank = ?, brand = ?, 
                        ratings = ?, stars = ?, image_url = ?, date = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE asin = ?
                """, (
                    product_data['title'],
                    current_price,
                    current_rank,
                    product_data['brand'],
                    product_data['ratings'],
                    product_data['stars'],
                    product_data['image_url'],
                    product_data['date'],
                    product_data['asin']
                ))
                print(f"Updated product: {product_data['title'][:50]}...")
                
                # Add to rank history if rank changed
                if current_rank and old_rank and current_rank != old_rank:
                    self.cursor.execute("""
                        INSERT INTO rank_history (asin, rank, price, recorded_at)
                        VALUES (?, ?, ?, CURRENT_TIMESTAMP)
                    """, (product_data['asin'], current_rank, current_price))
                    print(f"Rank history updated: {old_rank} -> {current_rank}")
                    
            else:
                # Insert new product
                self.cursor.execute("""
                    INSERT INTO products (name, price, rank, asin, brand, ratings, stars, image_url, date, url)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    product_data['title'],
                    current_price,
                    current_rank,
                    product_data['asin'],
                    product_data['brand'],
                    product_data['ratings'],
                    product_data['stars'],
                    product_data['image_url'],
                    product_data['date'],
                    product_data['url']
                ))
                print(f"Added new product: {product_data['title'][:50]}...")
                
                # Add initial rank history
                if current_rank:
                    self.cursor.execute("""
                        INSERT INTO rank_history (asin, rank, price, recorded_at)
                        VALUES (?, ?, ?, CURRENT_TIMESTAMP)
                    """, (product_data['asin'], current_rank, current_price))
                    print(f"Initial rank history added: {current_rank}")
            
            # Keep only last 5 rank history entries per ASIN
            self.cursor.execute("""
                DELETE FROM rank_history 
                WHERE asin = ? AND id NOT IN (
                    SELECT id FROM rank_history 
                    WHERE asin = ? 
                    ORDER BY recorded_at DESC 
                    LIMIT 5
                )
            """, (product_data['asin'], product_data['asin']))
            
            self.conn.commit()
            return True
            
        except Exception as e:
            print(f"Database error: {e}")
            return False

    def crawl_urls(self, urls):
        """Crawl multiple URLs and update database immediately"""
        if not self.connect_db():
            return False
        
        success_count = 0
        total_count = len(urls)
        
        print(f"Starting to crawl {total_count} Amazon URLs...")
        
        for i, url in enumerate(urls, 1):
            print(f"Progress: {i}/{total_count}")
            
            product_data = self.process_single_url(url)
            if product_data:
                if 'error' in product_data:
                    print(f"Product {i}/{total_count} error: {product_data['error']}")
                elif product_data['title'] not in ['Product Not Found', 'Error Processing']:
                    # Only update database if product was successfully crawled
                    if self.update_database(product_data):
                        success_count += 1
                        print(f"Product {i}/{total_count} added to database successfully")
                    else:
                        print(f"Failed to add product {i}/{total_count} to database")
                else:
                    print(f"Product {i}/{total_count} skipped - not found or error")
            else:
                print(f"Failed to crawl product {i}/{total_count}")
            
            # Add delay to be respectful to Amazon servers
            time.sleep(1)  # Reduced delay for faster updates
        
        print(f"Crawling completed. Successfully processed {success_count}/{total_count} URLs.")
        self.conn.close()
        return success_count > 0

def main():
    """Main function to handle input and start crawling"""
    try:
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