const express = require('express');
const ProductController = require('../controllers/ProductController');
const SettingsController = require('../controllers/SettingsController');
const serviceManager = require('../services/ServiceManager');
const logger = require('../utils/logger');

const router = express.Router();
const productController = new ProductController();
const settingsController = new SettingsController();

// Initialize ServiceManager and controllers
(async () => {
    try {
        await serviceManager.init();
        await productController.init();
        logger.info('ServiceManager and controllers initialized successfully');
    } catch (error) {
        logger.error(`Error initializing services: ${error.message}`);
    }
})();

// Product routes
router.get('/api/products', (req, res) => productController.getAllProducts(req, res));
router.get('/api/crawl-status', (req, res) => productController.getCrawlStatus(req, res));
router.post('/api/crawl', (req, res) => productController.crawlUrls(req, res));
router.delete('/api/products/:id', (req, res) => productController.deleteProduct(req, res));
router.put('/api/products/:id', (req, res) => productController.updateProduct(req, res));

// Settings routes
router.get('/api/settings/crawl-interval', (req, res) => settingsController.getCrawlInterval(req, res));
router.post('/api/settings/crawl-interval', (req, res) => settingsController.updateCrawlInterval(req, res));
router.post('/api/settings/clear-database', (req, res) => settingsController.clearDatabase(req, res));

module.exports = router; 