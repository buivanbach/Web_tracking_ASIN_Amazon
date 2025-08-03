#!/bin/bash

echo "🔧 Fix Python Path Issues on Ubuntu"
echo "==================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check current Python installation
echo "📋 Current Python Status:"
python3 --version 2>/dev/null || echo "python3: NOT FOUND"
python --version 2>/dev/null || echo "python: NOT FOUND"

# Create python symlink if needed
if command_exists python3 && ! command_exists python; then
    echo "🔗 Creating python symlink..."
    sudo ln -sf /usr/bin/python3 /usr/bin/python
    echo "✅ Python symlink created"
fi

# Add Python to PATH if not already there
echo "🔧 Checking PATH..."
if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
    echo "📝 Adding /usr/bin to PATH..."
    echo 'export PATH="/usr/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    echo "✅ PATH updated"
fi

# Install Python dependencies if missing
echo "📦 Installing Python dependencies..."
pip3 install --upgrade pip
pip3 install selenium beautifulsoup4 requests easyocr webdriver-manager

# Install Chrome and ChromeDriver if missing
if ! command_exists google-chrome; then
    echo "🌐 Installing Google Chrome..."
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    sudo apt install -y google-chrome-stable
    echo "✅ Chrome installed"
fi

if ! command_exists chromedriver; then
    echo "🚗 Installing ChromeDriver..."
    CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | awk -F'.' '{print $1}')
    CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION")
    wget -O /tmp/chromedriver.zip "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
    sudo unzip /tmp/chromedriver.zip -d /usr/local/bin/
    sudo chmod +x /usr/local/bin/chromedriver
    echo "✅ ChromeDriver installed"
fi

# Test Python commands
echo "🧪 Testing Python commands..."
python3 --version
python --version

# Test Python script
if [ -f "python/crawl_and_update_fixed.py" ]; then
    echo "🎯 Testing Python script..."
    echo '["https://www.amazon.com/dp/B08N5WRWNW"]' | python3 python/crawl_and_update_fixed.py
else
    echo "⚠️ Python script not found!"
fi

echo "✅ Python path fix completed!" 