# Ubuntu Installation Guide

Hướng dẫn cài đặt Web Tracking ASIN Amazon trên Ubuntu mới.

## 🚀 Quick Setup (Recommended)

### **Option 1: Auto Setup Script**
```bash
# Clone repository
git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
cd Web_tracking_ASIN_Amazon

# Make script executable
chmod +x setup-ubuntu.sh

# Run setup script
./setup-ubuntu.sh
```

### **Option 2: Manual Installation**

## 📋 Prerequisites

### **1. Update System**
```bash
sudo apt update && sudo apt upgrade -y
```

### **2. Install Essential Tools**
```bash
sudo apt install -y curl wget git build-essential
```

## 🔧 Install Dependencies

### **1. Install Node.js and npm**
```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### **2. Install Python 3 and pip**
```bash
# Install Python 3
sudo apt install -y python3 python3-pip python3-venv

# Verify installation
python3 --version
pip3 --version
```

### **3. Install Google Chrome**
```bash
# Add Google Chrome repository
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Update and install Chrome
sudo apt update
sudo apt install -y google-chrome-stable

# Verify installation
google-chrome --version
```

### **4. Install System Dependencies**
```bash
# Install dependencies for Python packages (OpenCV, etc.)
sudo apt install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1
```

## 📦 Install Project Dependencies

### **1. Clone Repository**
```bash
git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
cd Web_tracking_ASIN_Amazon
```

### **2. Install Node.js Dependencies**
```bash
npm install
```

### **3. Install Python Dependencies**
```bash
pip3 install -r python/requirements.txt
```

### **4. Create Project Directories**
```bash
mkdir -p data/logs
mkdir -p data/database
```

## 🚀 Run Application

### **Option 1: Using Run Script**
```bash
# Make script executable
chmod +x run-ubuntu.sh

# Run application
./run-ubuntu.sh
```

### **Option 2: Manual Run**
```bash
# Start the application
npm start

# Or directly
node server.js
```

## 🌐 Access Application

1. Open browser: http://localhost:3000
2. Go to URL Manager tab
3. Add Amazon URLs
4. Monitor crawling progress

## 🔧 Useful Commands

### **View Logs**
```bash
tail -f data/logs/app.log
```

### **Check Database**
```bash
sqlite3 data/database/database.db
```

### **Check Port Usage**
```bash
lsof -i :3000
```

### **Kill Process on Port 3000**
```bash
sudo kill -9 $(lsof -t -i:3000)
```

## 🐛 Troubleshooting

### **Node.js not found**
```bash
# Reinstall Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### **Python not found**
```bash
# Reinstall Python
sudo apt install -y python3 python3-pip
```

### **Chrome not found**
```bash
# Reinstall Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable
```

### **Permission denied**
```bash
# Make scripts executable
chmod +x setup-ubuntu.sh
chmod +x run-ubuntu.sh
```

### **Port 3000 in use**
```bash
# Kill process on port 3000
sudo kill -9 $(lsof -t -i:3000)
```

## 📊 System Requirements

- **OS**: Ubuntu 18.04 or later
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 1GB free space
- **Network**: Internet connection for crawling

## 🎯 Features After Installation

- ✅ **ASIN Tracking**: Monitor Amazon product ASINs
- ✅ **Automated Crawling**: Scheduled crawling
- ✅ **Real-time Updates**: Live UI updates
- ✅ **Persistent Settings**: Database storage
- ✅ **Modern UI**: Amazon-like interface
- ✅ **Trending Analysis**: Rank improvement detection 