#!/bin/bash

echo "🔍 Python Debug Script for Ubuntu AWS"
echo "====================================="

echo ""
echo "📋 System Information:"
echo "OS: $(uname -a)"
echo "User: $(whoami)"
echo "Current directory: $(pwd)"

echo ""
echo "🐍 Python Commands Check:"
echo "which python3: $(which python3 2>/dev/null || echo 'NOT FOUND')"
echo "which python: $(which python 2>/dev/null || echo 'NOT FOUND')"
echo "which py: $(which py 2>/dev/null || echo 'NOT FOUND')"

echo ""
echo "📊 Python Versions:"
python3 --version 2>/dev/null || echo "python3: NOT FOUND"
python --version 2>/dev/null || echo "python: NOT FOUND"
py --version 2>/dev/null || echo "py: NOT FOUND"

echo ""
echo "📦 Python Dependencies:"
python3 -c "import selenium; print('selenium: OK')" 2>/dev/null || echo "selenium: NOT FOUND"
python3 -c "import beautifulsoup4; print('beautifulsoup4: OK')" 2>/dev/null || echo "beautifulsoup4: NOT FOUND"
python3 -c "import requests; print('requests: OK')" 2>/dev/null || echo "requests: NOT FOUND"
python3 -c "import easyocr; print('easyocr: OK')" 2>/dev/null || echo "easyocr: NOT FOUND"

echo ""
echo "🌐 Chrome/ChromeDriver Check:"
which google-chrome 2>/dev/null || echo "google-chrome: NOT FOUND"
which chromedriver 2>/dev/null || echo "chromedriver: NOT FOUND"

echo ""
echo "📁 Project Files Check:"
ls -la python/ 2>/dev/null || echo "python/ directory: NOT FOUND"
ls -la python/crawl_and_update_fixed.py 2>/dev/null || echo "crawl_and_update_fixed.py: NOT FOUND"

echo ""
echo "🔧 PATH Environment:"
echo $PATH

echo ""
echo "📋 Current Directory Contents:"
ls -la

echo ""
echo "🎯 Test Python Script Execution:"
if [ -f "python/crawl_and_update_fixed.py" ]; then
    echo "Script exists, testing execution..."
    python3 python/crawl_and_update_fixed.py --help 2>&1 || echo "Script execution failed"
else
    echo "Script not found!"
fi 