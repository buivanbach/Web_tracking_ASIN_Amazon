const serviceManager = require('../services/ServiceManager');
const logger = require('../utils/logger');

class SettingsController {
    constructor() {
        // Services will be accessed via ServiceManager
    }

    async updateCrawlInterval(req, res) {
        try {
            const { interval } = req.body;
            
            logger.info(`Received crawl interval update request: ${interval}`);
            
            if (!interval || interval < 1 || interval > 24) {
                logger.error(`Invalid interval value: ${interval}`);
                return res.status(400).json({ error: 'Interval must be between 1 and 24 hours' });
            }
            
            logger.info(`Updating crawl interval to ${interval} hours`);
            await serviceManager.getCrawlerService().updateCrawlInterval(interval);
            
            logger.info(`Crawl interval updated successfully to ${interval} hours`);
            res.json({ 
                message: 'Crawl interval updated successfully', 
                interval 
            });
        } catch (error) {
            logger.error(`Error updating crawl interval: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }

    async getCrawlInterval(req, res) {
        try {
            const interval = serviceManager.getCrawlerService().crawlInterval;
            logger.info(`Getting current crawl interval: ${interval} hours`);
            res.json({ interval });
        } catch (error) {
            logger.error(`Error getting crawl interval: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }

    async clearDatabase(req, res) {
        try {
            await serviceManager.getCrawlerService().clearDatabase();
            res.json({ message: 'Database cleared successfully' });
        } catch (error) {
            logger.error(`Error clearing database: ${error.message}`);
            res.status(500).json({ error: error.message });
        }
    }
}

module.exports = SettingsController; 