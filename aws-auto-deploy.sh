#!/bin/bash

echo "🚀 AWS Auto Deploy Script - Web Tracking ASIN Amazon"
echo "==============================================="

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y
print_success "System updated"

# Install essential tools
print_status "Installing essential tools..."
apt install -y curl wget git build-essential htop
print_success "Essential tools installed"

# Install Node.js
if ! command_exists node; then
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    print_success "Node.js installed"
else
    print_success "Node.js already installed: $(node --version)"
fi

# Install Python
if ! command_exists python3; then
    print_status "Installing Python 3..."
    apt install -y python3 python3-pip python3-venv
    print_success "Python 3 installed"
else
    print_success "Python 3 already installed: $(python3 --version)"
fi

# Install Chrome
if ! command_exists google-chrome; then
    print_status "Installing Google Chrome..."
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
    apt update
    apt install -y google-chrome-stable
    print_success "Google Chrome installed"
else
    print_success "Google Chrome already installed: $(google-chrome --version)"
fi

# Install system dependencies
print_status "Installing system dependencies..."
apt install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1
print_success "System dependencies installed"

# Install PM2 globally
if ! command_exists pm2; then
    print_status "Installing PM2..."
    npm install -g pm2
    print_success "PM2 installed"
else
    print_success "PM2 already installed"
fi

# Configure firewall
print_status "Configuring firewall..."
if ! command_exists ufw; then
    apt install -y ufw
fi

ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 3000
print_success "Firewall configured"

# Clone repository if not exists
if [ ! -d "/home/ubuntu/Web_tracking_ASIN_Amazon" ]; then
    print_status "Cloning repository..."
    cd /home/ubuntu
    git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
    cd Web_tracking_ASIN_Amazon
    print_success "Repository cloned"
else
    print_status "Repository already exists, updating..."
    cd /home/ubuntu/Web_tracking_ASIN_Amazon
    git pull origin main
    print_success "Repository updated"
fi

# Install dependencies
print_status "Installing Node.js dependencies..."
npm install
print_success "Node.js dependencies installed"

print_status "Installing Python dependencies..."
pip3 install -r python/requirements.txt
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

# Create systemd service
print_status "Creating systemd service..."
cat > /etc/systemd/system/web-tracking.service << 'EOF'
[Unit]
Description=Web Tracking ASIN Amazon
After=network.target

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/home/ubuntu/Web_tracking_ASIN_Amazon
ExecStart=/usr/bin/pm2 start ecosystem.config.js
ExecStop=/usr/bin/pm2 stop ecosystem.config.js
ExecReload=/usr/bin/pm2 reload ecosystem.config.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
print_success "Systemd service created"

# Enable and start service
print_status "Enabling and starting service..."
systemctl daemon-reload
systemctl enable web-tracking
systemctl start web-tracking
print_success "Service started"

# Wait for service to start
print_status "Waiting for service to start..."
sleep 5

# Check service status
if systemctl is-active --quiet web-tracking; then
    print_success "Service is running"
else
    print_error "Service failed to start"
    systemctl status web-tracking
    exit 1
fi

# Get public IP
print_status "Getting public IP..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "$PUBLIC_IP" ]; then
    print_warning "Could not get public IP"
    PUBLIC_IP="YOUR_EC2_IP"
else
    print_success "Public IP: $PUBLIC_IP"
fi

# Test application
print_status "Testing application..."
sleep 3
if curl -s http://localhost:3000/health > /dev/null; then
    print_success "Application is accessible locally"
else
    print_error "Application is not accessible locally"
fi

echo ""
echo "🎉 Auto deployment completed successfully!"
echo "==============================================="
echo "📋 Application Information:"
echo "- Local URL: http://localhost:3000"
echo "- External URL: http://$PUBLIC_IP:3000"
echo "- Health Check: http://$PUBLIC_IP:3000/health"
echo ""
echo "🔧 Management Commands:"
echo "- Check status: sudo systemctl status web-tracking"
echo "- View logs: tail -f data/logs/app.log"
echo "- PM2 logs: pm2 logs web-tracking"
echo "- Restart: sudo systemctl restart web-tracking"
echo "- Stop: sudo systemctl stop web-tracking"
echo ""
echo "📊 Monitoring:"
echo "- PM2 status: pm2 status"
echo "- System resources: htop"
echo "- Port check: netstat -tlnp | grep 3000"
echo ""
echo "🌐 Your application is now running and accessible from the internet!"
echo "Access it at: http://$PUBLIC_IP:3000" 