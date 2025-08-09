const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const logger = require('./src/utils/logger');
const routes = require('./src/routes');
// Lazy import for node-fetch (ESM)
const fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.use(routes);

// Serve the main HTML page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Image proxy to avoid hotlink/Referer issues
app.get('/api/proxy-image', async (req, res) => {
    try {
        const url = req.query.url;
        if (!url || typeof url !== 'string') {
            return res.status(400).send('Missing url');
        }
        // Basic allowlist for Amazon image hosts
        const allowedHosts = [
            'amazon.com',
            'media-amazon.com',
            'ssl-images-amazon.com',
        ];
        const u = new URL(url);
        if (!allowedHosts.some((h) => u.hostname.endsWith(h))) {
            return res.status(400).send('Host not allowed');
        }
        const ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
        const response = await fetch(url, {
            headers: {
                'User-Agent': ua,
                'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.9',
                'Referer': 'https://www.amazon.com/',
            },
            redirect: 'follow',
        });
        if (!response.ok) {
            return res.status(response.status).send('Failed to fetch image');
        }
        const contentType = response.headers.get('content-type') || 'image/jpeg';
        const buffer = Buffer.from(await response.arrayBuffer());
        res.setHeader('Content-Type', contentType);
        res.setHeader('Cache-Control', 'public, max-age=86400');
        return res.send(buffer);
    } catch (err) {
        logger.error(`Proxy image error: ${err.message}`);
        return res.status(500).send('Proxy error');
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    logger.error(`Unhandled error: ${err.message}`);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
    logger.info(`Server started successfully on http://localhost:${PORT}`);
    logger.info('Web application is ready to use!');
});

// Graceful shutdown
process.on('SIGINT', () => {
    logger.info('Shutting down server gracefully...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    logger.info('Shutting down server gracefully...');
    process.exit(0);
}); 