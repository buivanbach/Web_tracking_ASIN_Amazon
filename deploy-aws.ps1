# Deploy Web Tracking ASIN Amazon on AWS Ubuntu
Write-Host "🚀 Deploying Web Tracking ASIN Amazon on AWS Ubuntu" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Configuration
$SERVER_IP = "3.24.240.42"
$PEM_FILE = ".\ubuntu_web.pem"
$USER = "ubuntu"

# Check if PEM file exists
if (-not (Test-Path $PEM_FILE)) {
    Write-Host "❌ PEM file not found: $PEM_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "✅ PEM file found: $PEM_FILE" -ForegroundColor Green

# Set proper permissions for PEM file
Write-Host "🔒 Setting PEM file permissions..." -ForegroundColor Yellow
icacls $PEM_FILE /inheritance:r /grant:r "$env:USERNAME:F"

# Test SSH connection
Write-Host "🔍 Testing SSH connection..." -ForegroundColor Yellow
$testResult = ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $PEM_FILE ${USER}@${SERVER_IP} "whoami" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SSH connection successful!" -ForegroundColor Green
} else {
    Write-Host "❌ SSH connection failed: $testResult" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Starting deployment..." -ForegroundColor Green
Write-Host "This may take 5-10 minutes..." -ForegroundColor Yellow

# Execute deployment commands
$deployCommands = @"
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
echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable

# Install ChromeDriver
CHROME_VERSION=\$(google-chrome --version | awk '{print \$3}' | awk -F'.' '{print \$1}')
CHROMEDRIVER_VERSION=\$(curl -s 'https://chromedriver.storage.googleapis.com/LATEST_RELEASE_\$CHROME_VERSION')
wget -O /tmp/chromedriver.zip 'https://chromedriver.storage.googleapis.com/\$CHROMEDRIVER_VERSION/chromedriver_linux64.zip'
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
if [ -d 'Web_tracking_ASIN_Amazon' ]; then
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
echo '=== Application Status ==='
pm2 status
echo '=== Firewall Status ==='
sudo ufw status
echo '=== Deployment completed! ==='
echo 'Access URLs:'
echo '- Application: http://$SERVER_IP:3000'
echo '- Health check: http://$SERVER_IP:3000/health'
"@

$deployResult = ssh -o StrictHostKeyChecking=no -i $PEM_FILE ${USER}@${SERVER_IP} $deployCommands 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    Write-Host "📋 Access URLs:" -ForegroundColor Cyan
    Write-Host "   - Application: http://$SERVER_IP:3000" -ForegroundColor White
    Write-Host "   - Health check: http://$SERVER_IP:3000/health" -ForegroundColor White
    Write-Host "📋 Management commands:" -ForegroundColor Cyan
    Write-Host "   - SSH: ssh -i `"$PEM_FILE`" $USER@$SERVER_IP" -ForegroundColor White
    Write-Host "   - PM2 status: pm2 status" -ForegroundColor White
    Write-Host "   - PM2 logs: pm2 logs" -ForegroundColor White
} else {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    Write-Host "Error output: $deployResult" -ForegroundColor Red
} 