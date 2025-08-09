const { spawn, execSync } = require('child_process');
const path = require('path');
const logger = require('../utils/logger');

class CrawlerService {
    constructor() {
        this.crawlInterval = 2; // Default 2 hours
        this.productModel = null;
    }

    async init() {
        // ProductModel will be injected via ServiceManager
        // Load crawl interval from database
        await this.loadCrawlIntervalFromDatabase();
    }

    setProductModel(productModel) {
        this.productModel = productModel;
    }

    async crawlUrls(urls) {
        logger.info(`Starting crawl for ${urls.length} URLs`);
        
        return new Promise(async (resolve, reject) => {
            // Try different Python commands
            const pythonCommands = ['python3', 'python', 'py'];
            let pythonProcess = null;
            let commandUsed = null;
            
            // First, check which Python command is available
            for (const command of pythonCommands) {
                try {
                    // Test if command exists using 'which' (Linux) or 'where' (Windows)
                    const isWindows = process.platform === 'win32';
                    const checkCommand = isWindows ? `where ${command}` : `which ${command}`;
                    
                    execSync(checkCommand, { stdio: 'ignore' });
                    commandUsed = command;
                    logger.info(`Found Python command: ${command}`);
                    break;
                } catch (error) {
                    logger.warn(`Python command '${command}' not found: ${error.message}`);
                    continue;
                }
            }
            
            if (!commandUsed) {
                const error = new Error('No Python command available. Please install Python and add it to PATH.');
                logger.error(error.message);
                reject(error);
                return;
            }
            
            // Resolve script path so it works regardless of working directory
            const scriptPath = path.join(__dirname, '..', '..', 'python', 'crawl_and_update_fixed.py');
            const repoRoot = path.join(__dirname, '..', '..');

            // Now spawn the process with the found command
            try {
                pythonProcess = spawn(commandUsed, [scriptPath], {
                    stdio: ['pipe', 'pipe', 'pipe'],
                    cwd: repoRoot
                });
                logger.info(`Using Python command: ${commandUsed}`);
            } catch (error) {
                logger.error(`Failed to spawn Python process with ${commandUsed}: ${error.message}`);
                reject(error);
                return;
            }

            // Send URLs to Python process
            pythonProcess.stdin.write(JSON.stringify(urls));
            pythonProcess.stdin.end();

            let output = '';
            let errorOutput = '';

            pythonProcess.stdout.on('data', (data) => {
                const message = data.toString().trim();
                output += message + '\n';
                logger.info(`Python crawler output: ${message}`);
            });

            pythonProcess.stderr.on('data', (data) => {
                const message = data.toString().trim();
                errorOutput += message + '\n';
                logger.error(`Python crawler error: ${message}`);
            });

            pythonProcess.on('close', async (code) => {
                if (code === 0) {
                    logger.info(`Crawling completed successfully with code ${code}`);
                    resolve({ success: true, output, errorOutput });
                } else {
                    logger.error(`Crawling failed with code ${code}`);
                    reject(new Error(`Crawling failed with code ${code}`));
                }
            });

            pythonProcess.on('error', (error) => {
                logger.error(`Failed to start Python process: ${error.message}`);
                reject(error);
            });
        });
    }

    async scheduleCrawling() {
        const cron = require('node-cron');
        
        // Clear existing schedules
        cron.getTasks().forEach(task => task.stop());
        
        // Schedule new crawl interval
        cron.schedule(`0 */${this.crawlInterval} * * *`, async () => {
            logger.info(`Running scheduled crawl (every ${this.crawlInterval} hours)...`);
            await this.runScheduledCrawl();
        });
        
        logger.info(`Crawl schedule set to every ${this.crawlInterval} hours`);
    }

    async runScheduledCrawl() {
        try {
            // Get URLs from database
            const urls = await this.getUrlsFromDatabase();
            
            if (urls.length === 0) {
                logger.info('No URLs found for scheduled crawl');
                return;
            }

            logger.info(`Scheduled crawl found ${urls.length} URLs to process`);
            await this.crawlUrls(urls);
            
        } catch (error) {
            logger.error(`Scheduled crawl failed: ${error.message}`);
        }
    }

    async getUrlsFromDatabase() {
        try {
            const result = await this.productModel.db.all(
                'SELECT urls FROM url_lists ORDER BY created_at DESC LIMIT 1'
            );
            
            if (result.length === 0) {
                return [];
            }

            return JSON.parse(result[0].urls);
        } catch (error) {
            logger.error(`Error getting URLs from database: ${error.message}`);
            return [];
        }
    }

    async saveUrlsToDatabase(urls) {
        try {
            const urlString = JSON.stringify(urls);
            await this.productModel.db.run(
                'INSERT INTO url_lists (urls) VALUES (?)',
                [urlString]
            );
            logger.info(`Saved ${urls.length} URLs to database`);
        } catch (error) {
            logger.error(`Error saving URLs to database: ${error.message}`);
            throw error;
        }
    }

    async loadCrawlIntervalFromDatabase() {
        try {
            const result = await this.productModel.db.get(
                'SELECT value FROM settings WHERE key = ?',
                ['crawl_interval']
            );
            
            if (result) {
                this.crawlInterval = parseInt(result.value);
                logger.info(`Loaded crawl interval from database: ${this.crawlInterval} hours`);
            } else {
                logger.info(`No crawl interval found in database, using default: ${this.crawlInterval} hours`);
            }
        } catch (error) {
            logger.error(`Error loading crawl interval from database: ${error.message}`);
        }
    }

    async saveCrawlIntervalToDatabase(interval) {
        try {
            await this.productModel.db.run(
                'INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)',
                ['crawl_interval', interval.toString()]
            );
            logger.info(`Saved crawl interval to database: ${interval} hours`);
        } catch (error) {
            logger.error(`Error saving crawl interval to database: ${error.message}`);
            throw error;
        }
    }

    async updateCrawlInterval(interval) {
        if (interval < 1 || interval > 24) {
            throw new Error('Interval must be between 1 and 24 hours');
        }
        
        this.crawlInterval = interval;
        await this.saveCrawlIntervalToDatabase(interval);
        await this.scheduleCrawling();
        logger.info(`Crawl interval updated to ${interval} hours`);
    }

    async clearDatabase() {
        try {
            await this.productModel.clearAll();
            logger.info('Database cleared successfully');
        } catch (error) {
            logger.error(`Error clearing database: ${error.message}`);
            throw error;
        }
    }
}

module.exports = CrawlerService; 