#!/bin/bash

echo "🚀 Deploying Web Tracking ASIN Amazon on AWS Ubuntu"
echo "=================================================="

# Configuration
SERVER_IP="3.24.240.42"
PEM_FILE="ubuntu_web.pem"
USER="ubuntu"

# Check if PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo "❌ PEM file not found: $PEM_FILE"
    exit 1
fi

echo "✅ PEM file found: $PEM_FILE"

# Set proper permissions for PEM file
echo "🔒 Setting PEM file permissions..."
chmod 600 "$PEM_FILE"

# Test SSH connection
echo "🔍 Testing SSH connection..."
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$PEM_FILE" ${USER}@${SERVER_IP} "whoami"

if [ $? -eq 0 ]; then
    echo "✅ SSH connection successful!"
else
    echo "❌ SSH connection failed!"
    exit 1
fi

echo "🚀 Starting deployment..."
echo "This may take 5-10 minutes..."

# Execute deployment commands
ssh -o StrictHostKeyChecking=no -i "$PEM_FILE" ${USER}@${SERVER_IP} << 'EOF'
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git build-essential htop

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt-get install -y nodejs

# Install Python 3
sudo apt install -y python3 python3-pip python3-venv
sudo ln -sf /usr/bin/python3 /usr/bin/python

# Install Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable

# Install ChromeDriver
CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | awk -F'.' '{print $1}')
CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
sudo unzip /tmp/chromedriver.zip -d /usr/local/bin/
sudo chmod +x /usr/local/bin/chromedriver

# Install system dependencies
sudo apt install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1

# Install PM2
sudo npm install -g pm2

# Configure firewall
sudo apt install -y ufw
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000

# Clone repository
cd /home/ubuntu
if [ -d "Web_tracking_ASIN_Amazon" ]; then
    cd Web_tracking_ASIN_Amazon
    git pull origin main
else
    git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
    cd Web_tracking_ASIN_Amazon
fi

# Install dependencies
npm install
pip3 install selenium beautifulsoup4 requests easyocr webdriver-manager

# Create directories
mkdir -p data/logs data/database

# Set permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/Web_tracking_ASIN_Amazon
chmod +x *.sh

# Create PM2 ecosystem file
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

# Start application
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Show status
echo "=== Application Status ==="
pm2 status
echo "=== Firewall Status ==="
sudo ufw status
echo "=== Deployment completed! ==="
echo "Access URLs:"
echo "- Application: http://3.24.240.42:3000"
echo "- Health check: http://3.24.240.42:3000/health"
EOF

if [ $? -eq 0 ]; then
    echo "✅ Deployment completed successfully!"
    echo "📋 Access URLs:"
    echo "   - Application: http://$SERVER_IP:3000"
    echo "   - Health check: http://$SERVER_IP:3000/health"
    echo "📋 Management commands:"
    echo "   - SSH: ssh -i $PEM_FILE $USER@$SERVER_IP"
    echo "   - PM2 status: pm2 status"
    echo "   - PM2 logs: pm2 logs"
else
    echo "❌ Deployment failed!"
fi 