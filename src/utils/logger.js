const fs = require('fs');
const path = require('path');

class Logger {
    constructor() {
        this.logDir = path.join(__dirname, '../../data/logs');
        this.logFile = path.join(this.logDir, 'app.log');
        this.ensureLogDirectory();
    }

    ensureLogDirectory() {
        if (!fs.existsSync(this.logDir)) {
            fs.mkdirSync(this.logDir, { recursive: true });
        }
    }

    formatMessage(message, type = 'INFO') {
        const timestamp = new Date().toISOString();
        return `[${timestamp}] [${type}] ${message}`;
    }

    writeToFile(message, type = 'INFO') {
        const formattedMessage = this.formatMessage(message, type);
        fs.appendFileSync(this.logFile, formattedMessage + '\n');
    }

    log(message, type = 'INFO') {
        const formattedMessage = this.formatMessage(message, type);
        console.log(formattedMessage);
        this.writeToFile(message, type);
    }

    error(message) {
        this.log(message, 'ERROR');
    }

    warn(message) {
        this.log(message, 'WARN');
    }

    info(message) {
        this.log(message, 'INFO');
    }

    debug(message) {
        this.log(message, 'DEBUG');
    }
}

module.exports = new Logger(); 