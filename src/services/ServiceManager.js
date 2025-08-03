const CrawlerService = require('./CrawlerService');
const Product = require('../models/Product');
const logger = require('../utils/logger');

class ServiceManager {
    constructor() {
        this.crawlerService = null;
        this.productModel = null;
        this.initialized = false;
    }

    async init() {
        if (this.initialized) {
            return;
        }

        logger.info('Initializing ServiceManager...');
        
        // Initialize Product model
        this.productModel = new Product();
        await this.productModel.init();
        
        // Initialize CrawlerService
        this.crawlerService = new CrawlerService();
        this.crawlerService.setProductModel(this.productModel);
        await this.crawlerService.init();
        await this.crawlerService.scheduleCrawling();
        
        this.initialized = true;
        logger.info('ServiceManager initialized successfully');
    }

    getCrawlerService() {
        if (!this.initialized) {
            throw new Error('ServiceManager not initialized');
        }
        return this.crawlerService;
    }

    getProductModel() {
        if (!this.initialized) {
            throw new Error('ServiceManager not initialized');
        }
        return this.productModel;
    }
}

// Singleton instance
const serviceManager = new ServiceManager();

module.exports = serviceManager; 