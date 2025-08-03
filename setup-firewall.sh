#!/bin/bash

echo "🔥 AWS Firewall Configuration Script"
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

print_status "Configuring firewall for AWS..."

# Install ufw if not installed
if ! command -v ufw &> /dev/null; then
    print_status "Installing ufw..."
    apt update
    apt install -y ufw
fi

# Enable ufw
print_status "Enabling ufw firewall..."
ufw --force enable

# Allow SSH (important!)
print_status "Allowing SSH..."
ufw allow ssh

# Allow HTTP and HTTPS
print_status "Allowing HTTP and HTTPS..."
ufw allow 80
ufw allow 443

# Allow port 3000 for the application
print_status "Allowing port 3000 for the application..."
ufw allow 3000

# Show firewall status
print_status "Firewall status:"
ufw status

print_success "Firewall configured successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Start the application: npm run start:prod"
echo "2. Access from external IP: http://YOUR_EC2_IP:3000"
echo "3. Check if port is open: sudo ufw status"
echo ""
echo "🔧 Useful commands:"
echo "- Check firewall status: sudo ufw status"
echo "- Check open ports: sudo netstat -tlnp"
echo "- Check application logs: tail -f data/logs/app.log"
echo "" 