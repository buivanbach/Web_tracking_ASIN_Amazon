#!/bin/bash

echo "🚀 Web Tracking ASIN Amazon - Ubuntu Setup Script"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_success "System packages updated"

# Install essential build tools
print_status "Installing essential build tools..."
sudo apt install -y curl wget git build-essential
print_success "Build tools installed"

# Install Node.js and npm
print_status "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
print_success "Node.js and npm installed"

# Verify Node.js and npm installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js version: $NODE_VERSION"
print_success "npm version: $NPM_VERSION"

# Install Python 3 and pip
print_status "Installing Python 3 and pip..."
sudo apt install -y python3 python3-pip python3-venv
print_success "Python 3 and pip installed"

# Verify Python installation
PYTHON_VERSION=$(python3 --version)
PIP_VERSION=$(pip3 --version)
print_success "Python version: $PYTHON_VERSION"
print_success "pip version: $PIP_VERSION"

# Install Chrome/Chromium for Selenium
print_status "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable
print_success "Google Chrome installed"

# Verify Chrome installation
CHROME_VERSION=$(google-chrome --version)
print_success "Chrome version: $CHROME_VERSION"

# Install additional system dependencies for Python packages
print_status "Installing system dependencies for Python packages..."
sudo apt install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1
print_success "System dependencies installed"

# Create project directories
print_status "Creating project directories..."
mkdir -p data/logs
mkdir -p data/database
print_success "Project directories created"

# Install Node.js dependencies
print_status "Installing Node.js dependencies..."
npm install
print_success "Node.js dependencies installed"

# Install Python dependencies
print_status "Installing Python dependencies..."
pip3 install -r python/requirements.txt
print_success "Python dependencies installed"

# Set up environment
print_status "Setting up environment..."
export PATH="$PATH:/usr/local/bin"
print_success "Environment configured"

echo ""
echo "🎉 Setup completed successfully!"
echo "==============================================="
echo "📋 Next steps:"
echo "1. Run the application: ./run-ubuntu.sh"
echo "2. Open browser: http://localhost:3000"
echo "3. Go to URL Manager tab to add Amazon URLs"
echo ""
echo "📁 Project structure:"
echo "- Backend: src/"
echo "- Frontend: public/"
echo "- Python crawler: python/"
echo "- Database: data/database/"
echo "- Logs: data/logs/"
echo ""
echo "🔧 Useful commands:"
echo "- Start app: ./run-ubuntu.sh"
echo "- View logs: tail -f data/logs/app.log"
echo "- Check database: sqlite3 data/database/database.db"
echo "" 