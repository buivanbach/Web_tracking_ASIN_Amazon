const express = require('express');
const path = require('path');
const logger = require('./src/utils/logger');
const serviceManager = require('./src/services/ServiceManager');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0'; // Listen on all interfaces

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize ServiceManager
serviceManager.init();

// Import routes
const routes = require('./src/routes');

// Use routes
app.use('/api', routes);

// Serve main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Start server
app.listen(PORT, HOST, () => {
    logger.info(`🚀 Production server started on http://${HOST}:${PORT}`);
    logger.info(`🌐 Server is accessible from external IP`);
    logger.info(`📊 Health check: http://${HOST}:${PORT}/health`);
    logger.info(`📋 Application: http://${HOST}:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    process.exit(0);
}); 