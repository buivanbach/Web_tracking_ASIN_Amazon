#!/bin/bash

echo "🚀 Deploying Web Tracking ASIN Amazon on AWS Ubuntu"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Install essential tools
print_status "Installing essential tools..."
apt install -y curl wget git build-essential htop
print_success "Essential tools installed"

# Install Node.js
print_status "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
print_success "Node.js installed: $(node --version)"

# Install Python 3
print_status "Installing Python 3..."
apt install -y python3 python3-pip python3-venv
print_success "Python 3 installed: $(python3 --version)"

# Create python symlink
print_status "Creating Python symlink..."
ln -sf /usr/bin/python3 /usr/bin/python
print_success "Python symlink created"

# Install Chrome
print_status "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
apt update
apt install -y google-chrome-stable
print_success "Google Chrome installed"

# Install ChromeDriver
print_status "Installing ChromeDriver..."
CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | awk -F'.' '{print $1}')
CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
unzip /tmp/chromedriver.zip -d /usr/local/bin/
chmod +x /usr/local/bin/chromedriver
print_success "ChromeDriver installed"

# Install system dependencies
print_status "Installing system dependencies..."
apt install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1
print_success "System dependencies installed"

# Install PM2 globally
print_status "Installing PM2..."
npm install -g pm2
print_success "PM2 installed"

# Configure firewall
print_status "Configuring firewall..."
apt install -y ufw
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 3000
print_success "Firewall configured"

# Clone repository
print_status "Cloning repository..."
cd /home/ubuntu
if [ -d "Web_tracking_ASIN_Amazon" ]; then
    cd Web_tracking_ASIN_Amazon
    git pull origin main
    print_success "Repository updated"
else
    git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
    cd Web_tracking_ASIN_Amazon
    print_success "Repository cloned"
fi

# Install dependencies
print_status "Installing Node.js dependencies..."
npm install
print_success "Node.js dependencies installed"

print_status "Installing Python dependencies..."
pip3 install selenium beautifulsoup4 requests easyocr webdriver-manager
print_success "Python dependencies installed"

# Create directories
print_status "Creating project directories..."
mkdir -p data/logs data/database
print_success "Directories created"

# Set permissions
print_status "Setting permissions..."
chown -R ubuntu:ubuntu /home/ubuntu/Web_tracking_ASIN_Amazon
chmod +x *.sh
print_success "Permissions set"

# Create PM2 ecosystem file
print_status "Creating PM2 ecosystem file..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'web-tracking',
    script: 'server-production.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      HOST: '0.0.0.0'
    },
    error_file: './data/logs/pm2-error.log',
    out_file: './data/logs/pm2-out.log',
    log_file: './data/logs/pm2-combined.log',
    time: true
  }]
};
EOF
print_success "PM2 ecosystem file created"

# Start application
print_status "Starting application..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup
print_success "Application started"

# Show status
print_status "Application status:"
pm2 status

print_status "Firewall status:"
ufw status

print_success "🎉 Deployment completed!"
print_status "📋 Access URLs:"
print_status "   - Application: http://3.27.173.226:3000"
print_status "   - Health check: http://3.27.173.226:3000/health"
print_status "📋 Management commands:"
print_status "   - PM2 status: pm2 status"
print_status "   - PM2 logs: pm2 logs"
print_status "   - PM2 restart: pm2 restart web-tracking"
print_status "   - PM2 stop: pm2 stop web-tracking" 