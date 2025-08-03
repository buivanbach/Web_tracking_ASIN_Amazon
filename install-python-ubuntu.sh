#!/bin/bash

echo "🐍 Installing Python and dependencies on Ubuntu..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python 3 and pip
echo "🐍 Installing Python 3 and pip..."
sudo apt install -y python3 python3-pip python3-venv

# Install system dependencies for Chrome/Selenium
echo "🌐 Installing Chrome and system dependencies..."
sudo apt install -y wget unzip curl

# Install Google Chrome
echo "🌐 Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable

# Install ChromeDriver
echo "🚗 Installing ChromeDriver..."
CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | awk -F'.' '{print $1}')
CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
sudo unzip /tmp/chromedriver.zip -d /usr/local/bin/
sudo chmod +x /usr/local/bin/chromedriver

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip3 install selenium beautifulsoup4 requests easyocr webdriver-manager

# Create symlink for python command
echo "🔗 Creating python symlink..."
sudo ln -sf /usr/bin/python3 /usr/bin/python

# Verify installation
echo "✅ Verifying installation..."
python3 --version
pip3 --version
google-chrome --version
chromedriver --version

echo "🎉 Python installation completed!"
echo "📋 Available commands:"
echo "   - python3"
echo "   - python (symlink to python3)"
echo "   - pip3"
echo "   - google-chrome"
echo "   - chromedriver" 