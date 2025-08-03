const serviceManager = require('../services/ServiceManager');
const logger = require('../utils/logger');

class ProductController {
    constructor() {
        // Services will be initialized via ServiceManager
    }

    async init() {
        await serviceManager.init();
    }

    async getAllProducts(req, res) {
        try {
            logger.info('GET /api/products - Fetching all products with trending data');
            const result = await serviceManager.getProductModel().getAllWithTrending();
            res.json(result);
        } catch (error) {
            logger.error(`Error fetching products: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }

    async getCrawlStatus(req, res) {
        try {
            const { urls } = req.query;
            
            if (!urls) {
                return res.status(400).json({ error: 'URLs parameter required' });
            }

            const urlList = JSON.parse(urls);
            const status = await serviceManager.getProductModel().getByUrls(urlList);
            res.json(status);
        } catch (error) {
            logger.error(`Error fetching crawl status: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }

    async crawlUrls(req, res) {
        try {
            const { urls } = req.body;
            
            logger.info(`POST /api/crawl - Received ${urls ? urls.length : 0} URLs for crawling`);
            
            if (!urls || !Array.isArray(urls) || urls.length === 0) {
                logger.error('URLs array is required');
                return res.status(400).json({ error: 'URLs array is required' });
            }

            // Save URLs to database
            await serviceManager.getCrawlerService().saveUrlsToDatabase(urls);
            
            // Start crawling
            await serviceManager.getCrawlerService().crawlUrls(urls);
            
            res.json({ message: 'Crawling started successfully' });
        } catch (error) {
            logger.error(`Error starting crawl: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }

    async deleteProduct(req, res) {
        try {
            const { id } = req.params;
            const result = await serviceManager.getProductModel().delete(id);
            
            if (result.changes === 0) {
                return res.status(404).json({ error: 'Product not found' });
            }
            
            res.json({ message: 'Product deleted successfully' });
        } catch (error) {
            logger.error(`Error deleting product: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }

    async updateProduct(req, res) {
        try {
            const { id } = req.params;
            const productData = req.body;
            
            const result = await serviceManager.getProductModel().update(id, productData);
            
            if (result.changes === 0) {
                return res.status(404).json({ error: 'Product not found' });
            }
            
            res.json({ message: 'Product updated successfully' });
        } catch (error) {
            logger.error(`Error updating product: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }
}

module.exports = ProductController; 