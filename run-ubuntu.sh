#!/bin/bash

echo "🚀 Web Tracking ASIN Amazon - Ubuntu Run Script"
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

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Please run setup first: ./setup-ubuntu.sh"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm not found. Please run setup first: ./setup-ubuntu.sh"
    exit 1
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 not found. Please run setup first: ./setup-ubuntu.sh"
    exit 1
fi

# Check if Chrome is installed
if ! command -v google-chrome &> /dev/null; then
    print_warning "Google Chrome not found. Please run setup first: ./setup-ubuntu.sh"
fi

print_success "All dependencies found"

# Check if port 3000 is in use
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    print_warning "Port 3000 is already in use"
    print_warning "The application might already be running"
    echo "🌐 Try opening: http://localhost:3000"
    echo ""
    read -p "Do you want to kill the existing process? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo kill -9 $(lsof -t -i:3000)
        print_success "Killed existing process"
        sleep 2
    fi
fi

echo ""
echo "📋 Application Information:"
echo "- URL: http://localhost:3000"
echo "- Logs: data/logs/app.log"
echo "- Database: data/database/database.db"
echo ""
echo "🔧 Commands:"
echo "- Stop: Ctrl+C"
echo "- Restart: Run this script again"
echo ""
echo "🎯 Usage:"
echo "1. Open browser: http://localhost:3000"
echo "2. Go to URL Manager tab"
echo "3. Add Amazon URLs"
echo "4. Monitor crawling progress"
echo ""
echo "⏳ Starting server..."
echo ""

# Start the application
npm start 