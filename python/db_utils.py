import os
import sqlite3


class DatabaseManager:
    def __init__(self, db_path: str):
        self.db_path = db_path
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)

    def connect(self):
        self.conn = sqlite3.connect(self.db_path)
        self.cursor = self.conn.cursor()

    def close(self):
        try:
            if hasattr(self, 'conn'):
                self.conn.close()
        except Exception:
            pass

    def init_tables(self):
        self.connect()
        # products
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

        # rank_history
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

        # url_lists
        self.cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS url_lists (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                urls TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

        # settings
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

        # default crawl interval
        self.cursor.execute(
            """
            INSERT OR IGNORE INTO settings (key, value) VALUES ('crawl_interval', '2')
            """
        )

        self.conn.commit()
        self.close()

    # Query helpers
    def get_product_by_asin(self, asin: str):
        self.connect()
        self.cursor.execute('SELECT id, rank FROM products WHERE asin = ?', (asin,))
        row = self.cursor.fetchone()
        self.close()
        return row

    def create_product(self, product):
        self.connect()
        try:
            self.cursor.execute(
                '''INSERT INTO products (name, price, rank, asin, brand, ratings, stars, image_url, date, url)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                (
                    product['title'],
                    None if product['price'] in ['Not found', 'N/A'] else product['price'],
                    None if product['rank'] in ['Not found', 'N/A'] else product['rank'],
                    product['asin'],
                    product['brand'],
                    product['ratings'],
                    product['stars'],
                    product['image_url'],
                    product['date'],
                    product['url'],
                ),
            )
            self.conn.commit()
        except Exception as e:
            # Likely UNIQUE constraint on asin -> perform UPDATE instead
            try:
                self.cursor.execute(
                    '''UPDATE products SET name=?, price=?, rank=?, brand=?, ratings=?, stars=?, image_url=?, date=?, url=?, updated_at=CURRENT_TIMESTAMP
                       WHERE asin=?''',
                    (
                        product['title'],
                        None if product['price'] in ['Not found', 'N/A'] else product['price'],
                        None if product['rank'] in ['Not found', 'N/A'] else product['rank'],
                        product['brand'],
                        product['ratings'],
                        product['stars'],
                        product['image_url'],
                        product['date'],
                        product['url'],
                        product['asin'],
                    ),
                )
                self.conn.commit()
            finally:
                pass
        finally:
            self.close()

    def update_product(self, asin: str, product):
        self.connect()
        self.cursor.execute(
            '''UPDATE products SET name=?, price=?, rank=?, brand=?, ratings=?, stars=?, image_url=?, date=?, updated_at=CURRENT_TIMESTAMP WHERE asin=?''',
            (
                product['title'],
                product['price'] if product['price'] not in ['Not found', 'N/A'] else None,
                product['rank'] if product['rank'] not in ['Not found', 'N/A'] else None,
                product['brand'],
                product['ratings'],
                product['stars'],
                product['image_url'],
                product['date'],
                asin,
            ),
        )
        self.conn.commit()
        self.close()

    def add_rank_history(self, asin: str, rank, price):
        # Require a numeric rank; otherwise skip to respect NOT NULL constraint
        try:
            if rank in ['Not found', 'N/A', None]:
                return
            rank_int = int(str(rank).replace(',', ''))
        except Exception:
            return

        price_val = None
        try:
            if price not in ['Not found', 'N/A', None]:
                price_val = float(str(price).replace(',', '').replace('$', ''))
        except Exception:
            price_val = None

        self.connect()
        self.cursor.execute(
            'INSERT INTO rank_history (asin, rank, price, recorded_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)',
            (asin, rank_int, price_val),
        )
        self.conn.commit()
        self.close()

    def cleanup_rank_history(self, asin: str):
        self.connect()
        self.cursor.execute(
            '''DELETE FROM rank_history WHERE asin = ? AND id NOT IN (
                   SELECT id FROM rank_history WHERE asin = ? ORDER BY recorded_at DESC LIMIT 5
               )''',
            (asin, asin),
        )
        self.conn.commit()
        self.close()


