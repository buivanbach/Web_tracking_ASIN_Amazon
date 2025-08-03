const Database = require('../config/database');
const logger = require('../utils/logger');

class Product {
    constructor() {
        this.db = new Database();
    }

    async init() {
        await this.db.connect();
        await this.db.initTables();
    }

    async getAllWithTrending() {
        const query = `
            SELECT 
                p.*,
                CASE 
                    WHEN p.updated_at IS NOT NULL 
                    THEN CASE 
                        WHEN julianday('now') - julianday(p.updated_at) < 1/24 THEN 
                            CAST(ROUND((julianday('now') - julianday(p.updated_at)) * 24 * 60) AS INTEGER) || ' minutes ago'
                        WHEN julianday('now') - julianday(p.updated_at) < 1 THEN 
                            CAST(ROUND((julianday('now') - julianday(p.updated_at)) * 24) AS INTEGER) || ' hours ago'
                        ELSE 
                            CAST(ROUND(julianday('now') - julianday(p.updated_at)) AS INTEGER) || ' days ago'
                    END
                    ELSE 'Never updated'
                END as last_update,
                CASE 
                    WHEN rh1.rank IS NOT NULL AND rh2.rank IS NOT NULL 
                    THEN ROUND(((rh2.rank - rh1.rank) / rh1.rank) * 100, 2)
                    ELSE NULL
                END as rank_change_percent,
                CASE 
                    WHEN rh1.rank IS NOT NULL AND rh2.rank IS NOT NULL 
                    THEN CASE 
                        WHEN rh1.rank < rh2.rank THEN 'up'
                        WHEN rh1.rank > rh2.rank THEN 'down'
                        ELSE 'stable'
                    END
                    ELSE 'new'
                END as rank_trend,
                (
                    SELECT GROUP_CONCAT(rank ORDER BY recorded_at DESC)
                    FROM rank_history rh
                    WHERE rh.asin = p.asin
                    ORDER BY recorded_at DESC
                    LIMIT 5
                ) as rank_history
            FROM products p
            LEFT JOIN (
                SELECT asin, rank, recorded_at
                FROM rank_history 
                WHERE recorded_at = (
                    SELECT MAX(recorded_at) 
                    FROM rank_history rh2 
                    WHERE rh2.asin = rank_history.asin
                )
            ) rh1 ON p.asin = rh1.asin
            LEFT JOIN (
                SELECT asin, rank, recorded_at
                FROM rank_history 
                WHERE recorded_at = (
                    SELECT recorded_at 
                    FROM rank_history rh3 
                    WHERE rh3.asin = rank_history.asin 
                    ORDER BY recorded_at DESC 
                    LIMIT 1 OFFSET 1
                )
            ) rh2 ON p.asin = rh2.asin
            ORDER BY p.rank ASC, p.name ASC
        `;

        try {
            const products = await this.db.all(query);
            const trendingProducts = products.filter(product => 
                product.rank_change_percent && product.rank_change_percent > 10
            );

            logger.info(`Successfully fetched ${products.length} products, ${trendingProducts.length} trending`);
            return { products, trending: trendingProducts };
        } catch (error) {
            logger.error(`Error fetching products: ${error.message}`);
            throw error;
        }
    }

    async getByUrls(urls) {
        const query = `
            SELECT url, name, updated_at 
            FROM products 
            WHERE url IN (${urls.map(() => '?').join(',')})
        `;

        try {
            const products = await this.db.all(query, urls);
            const status = {};
            
            urls.forEach(url => {
                const product = products.find(row => row.url === url);
                status[url] = product ? {
                    crawled: true,
                    name: product.name,
                    updated_at: product.updated_at
                } : {
                    crawled: false
                };
            });

            return status;
        } catch (error) {
            logger.error(`Error fetching crawl status: ${error.message}`);
            throw error;
        }
    }

    async create(productData) {
        const query = `
            INSERT INTO products (name, price, rank, asin, brand, ratings, stars, image_url, date, url)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        const params = [
            productData.title,
            productData.price === 'Not found' || productData.price === 'N/A' ? null : productData.price,
            productData.rank === 'Not found' || productData.rank === 'N/A' ? null : productData.rank,
            productData.asin,
            productData.brand,
            productData.ratings,
            productData.stars,
            productData.image_url,
            productData.date,
            productData.url
        ];

        try {
            const result = await this.db.run(query, params);
            logger.info(`Added new product: ${productData.title.substring(0, 50)}...`);
            return result;
        } catch (error) {
            logger.error(`Error creating product: ${error.message}`);
            throw error;
        }
    }

    async update(asin, productData) {
        const query = `
            UPDATE products 
            SET name = ?, price = ?, rank = ?, brand = ?, 
                ratings = ?, stars = ?, image_url = ?, date = ?, updated_at = CURRENT_TIMESTAMP
            WHERE asin = ?
        `;

        const params = [
            productData.title,
            productData.price === 'Not found' || productData.price === 'N/A' ? null : productData.price,
            productData.rank === 'Not found' || productData.rank === 'N/A' ? null : productData.rank,
            productData.brand,
            productData.ratings,
            productData.stars,
            productData.image_url,
            productData.date,
            asin
        ];

        try {
            const result = await this.db.run(query, params);
            logger.info(`Updated product: ${productData.title.substring(0, 50)}...`);
            return result;
        } catch (error) {
            logger.error(`Error updating product: ${error.message}`);
            throw error;
        }
    }

    async delete(id) {
        const query = 'DELETE FROM products WHERE id = ?';
        
        try {
            const result = await this.db.run(query, [id]);
            logger.info(`Deleted product with ID: ${id}`);
            return result;
        } catch (error) {
            logger.error(`Error deleting product: ${error.message}`);
            throw error;
        }
    }

    async getByAsin(asin) {
        const query = 'SELECT * FROM products WHERE asin = ?';
        
        try {
            return await this.db.get(query, [asin]);
        } catch (error) {
            logger.error(`Error getting product by ASIN: ${error.message}`);
            throw error;
        }
    }

    async addRankHistory(asin, rank, price) {
        const query = `
            INSERT INTO rank_history (asin, rank, price, recorded_at)
            VALUES (?, ?, ?, CURRENT_TIMESTAMP)
        `;

        try {
            await this.db.run(query, [asin, rank, price]);
            logger.info(`Rank history added: ${rank}`);
        } catch (error) {
            logger.error(`Error adding rank history: ${error.message}`);
            throw error;
        }
    }

    async cleanupRankHistory(asin) {
        const query = `
            DELETE FROM rank_history 
            WHERE asin = ? AND id NOT IN (
                SELECT id FROM rank_history 
                WHERE asin = ? 
                ORDER BY recorded_at DESC 
                LIMIT 5
            )
        `;

        try {
            await this.db.run(query, [asin, asin]);
        } catch (error) {
            logger.error(`Error cleaning up rank history: ${error.message}`);
            throw error;
        }
    }

    async clearAll() {
        try {
            await this.db.run('DELETE FROM products');
            await this.db.run('DELETE FROM url_lists');
            await this.db.run('DELETE FROM rank_history');
            logger.info('Database cleared successfully');
        } catch (error) {
            logger.error(`Error clearing database: ${error.message}`);
            throw error;
        }
    }
}

module.exports = Product; 