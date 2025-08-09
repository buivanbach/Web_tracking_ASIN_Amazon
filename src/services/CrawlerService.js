const { spawn, spawnSync } = require('child_process');
const path = require('path');
const logger = require('../utils/logger');

// Detect a working Python command across platforms
function findWorkingPythonCommand() {
    const isWindows = process.platform === 'win32';

    // Each candidate can include required prefix args (e.g., -3 for py)
    const candidates = isWindows
        ? [
            { cmd: 'py', args: ['-3'] },
            { cmd: 'py', args: [] },
            { cmd: 'python', args: [] },
            { cmd: 'python3', args: [] },
        ]
        : [
            { cmd: 'python3', args: [] },
            { cmd: 'python', args: [] },
        ];

    for (const candidate of candidates) {
        try {
            // Validate by executing "--version" and requiring a version-like output
            const result = spawnSync(candidate.cmd, [...candidate.args, '--version'], {
                encoding: 'utf8',
                windowsHide: true,
            });

            const combinedOutput = `${result.stdout || ''}${result.stderr || ''}`.trim();
            const hasVersion = /Python\s+\d+\.\d+\.\d+/i.test(combinedOutput);

            if (result.status === 0 && hasVersion) {
                logger.info(`Detected Python interpreter: ${candidate.cmd} ${candidate.args.join(' ')}`.trim());
                return candidate;
            }

            // Log why this candidate was skipped (use debug level to avoid noise)
            logger.debug(
                `Skipping Python candidate '${candidate.cmd} ${candidate.args.join(' ')}' - status: ${result.status}, output: ${combinedOutput}`
            );
        } catch (error) {
            // Candidate not runnable
            logger.debug(`Python candidate '${candidate.cmd} ${candidate.args.join(' ')}' failed: ${error.message}`);
        }
    }

    return null;
}

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
            let pythonProcess = null;

            const detected = findWorkingPythonCommand();
            if (!detected) {
                const isWindows = process.platform === 'win32';
                const helpMessage = isWindows
                    ? 'Install Python 3.x from python.org and ensure the "py" launcher or "python" is in PATH. Also consider disabling Windows App Execution Aliases for python/python3.'
                    : 'Install Python 3.x (e.g., sudo apt-get install python3) and ensure python3 is available in PATH.';
                const error = new Error(`No working Python interpreter found. ${helpMessage}`);
                logger.error(error.message);
                reject(error);
                return;
            }

            // Resolve script path so it works regardless of working directory
            const scriptPath = path.join(__dirname, '..', '..', 'python', 'crawl_and_update_fixed.py');
            const repoRoot = path.join(__dirname, '..', '..');

            // Now spawn the process with the found command
            try {
                const spawnArgs = [...detected.args, scriptPath];
                pythonProcess = spawn(detected.cmd, spawnArgs, {
                    stdio: ['pipe', 'pipe', 'pipe'],
                    cwd: repoRoot,
                    env: { ...process.env, PYTHONIOENCODING: 'utf-8' },
                });
                logger.info(`Using Python command: ${detected.cmd} ${detected.args.join(' ')}`.trim());
            } catch (error) {
                logger.error(`Failed to spawn Python process with ${detected.cmd}: ${error.message}`);
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