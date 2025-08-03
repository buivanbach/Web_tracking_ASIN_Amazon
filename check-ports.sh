#!/bin/bash

echo "🔍 Port and Connection Check Script"
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

# Get EC2 public IP
print_status "Getting EC2 public IP..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "$PUBLIC_IP" ]; then
    print_warning "Could not get public IP from metadata"
    PUBLIC_IP="YOUR_EC2_IP"
else
    print_success "Public IP: $PUBLIC_IP"
fi

echo ""

# Check if application is running
print_status "Checking if application is running..."
if pgrep -f "node.*server" > /dev/null; then
    print_success "Application is running"
else
    print_error "Application is not running"
    echo "Start application with: npm run start:prod"
fi

echo ""

# Check if port 3000 is listening
print_status "Checking if port 3000 is listening..."
if netstat -tlnp 2>/dev/null | grep :3000 > /dev/null; then
    print_success "Port 3000 is listening"
    netstat -tlnp | grep :3000
else
    print_error "Port 3000 is not listening"
fi

echo ""

# Check firewall status
print_status "Checking firewall status..."
if command -v ufw > /dev/null; then
    UFW_STATUS=$(sudo ufw status)
    if echo "$UFW_STATUS" | grep -q "Status: active"; then
        print_success "Firewall is active"
        if echo "$UFW_STATUS" | grep -q "3000"; then
            print_success "Port 3000 is allowed in firewall"
        else
            print_error "Port 3000 is not allowed in firewall"
            echo "Run: sudo ufw allow 3000"
        fi
    else
        print_warning "Firewall is not active"
    fi
else
    print_warning "ufw not installed"
fi

echo ""

# Check if port is accessible locally
print_status "Testing local port accessibility..."
if curl -s http://localhost:3000/health > /dev/null; then
    print_success "Application is accessible locally"
else
    print_error "Application is not accessible locally"
fi

echo ""

# Check if port is accessible from outside
print_status "Testing external port accessibility..."
if curl -s --connect-timeout 5 http://$PUBLIC_IP:3000/health > /dev/null; then
    print_success "Application is accessible from internet"
    echo "🌐 Access URL: http://$PUBLIC_IP:3000"
else
    print_error "Application is not accessible from internet"
    echo "Check Security Group in AWS Console"
fi

echo ""

# Check system resources
print_status "Checking system resources..."
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo "Memory Usage:"
free -h | grep Mem | awk '{print $3 "/" $2}'

echo "Disk Usage:"
df -h / | tail -1 | awk '{print $5}'

echo ""

# Check application logs
print_status "Recent application logs:"
if [ -f "data/logs/app.log" ]; then
    tail -5 data/logs/app.log
else
    print_warning "No log file found"
fi

echo ""
echo "📋 Summary:"
echo "==========="
echo "Public IP: $PUBLIC_IP"
echo "Local URL: http://localhost:3000"
echo "External URL: http://$PUBLIC_IP:3000"
echo "Health Check: http://$PUBLIC_IP:3000/health"
echo ""
echo "🔧 Troubleshooting Commands:"
echo "- Check application: ps aux | grep node"
echo "- Check ports: netstat -tlnp | grep 3000"
echo "- Check firewall: sudo ufw status"
echo "- Check logs: tail -f data/logs/app.log"
echo "- Restart app: npm run start:prod" 