#!/bin/bash

echo "🔧 Service Management Script - Web Tracking ASIN Amazon"
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

# Function to show menu
show_menu() {
    echo ""
    echo "🔧 Service Management Options:"
    echo "1. Start service"
    echo "2. Stop service"
    echo "3. Restart service"
    echo "4. Check status"
    echo "5. View logs"
    echo "6. Update application"
    echo "7. Monitor resources"
    echo "8. Check ports"
    echo "9. Get public IP"
    echo "10. Test application"
    echo "0. Exit"
    echo ""
    read -p "Choose an option: " choice
}

# Function to start service
start_service() {
    print_status "Starting web-tracking service..."
    sudo systemctl start web-tracking
    if systemctl is-active --quiet web-tracking; then
        print_success "Service started successfully"
    else
        print_error "Failed to start service"
        sudo systemctl status web-tracking
    fi
}

# Function to stop service
stop_service() {
    print_status "Stopping web-tracking service..."
    sudo systemctl stop web-tracking
    print_success "Service stopped"
}

# Function to restart service
restart_service() {
    print_status "Restarting web-tracking service..."
    sudo systemctl restart web-tracking
    sleep 3
    if systemctl is-active --quiet web-tracking; then
        print_success "Service restarted successfully"
    else
        print_error "Failed to restart service"
        sudo systemctl status web-tracking
    fi
}

# Function to check status
check_status() {
    print_status "Checking service status..."
    sudo systemctl status web-tracking --no-pager
    echo ""
    print_status "PM2 status:"
    pm2 status
}

# Function to view logs
view_logs() {
    echo ""
    echo "📋 Log Options:"
    echo "1. Application logs"
    echo "2. PM2 logs"
    echo "3. System service logs"
    echo "4. Recent logs (last 20 lines)"
    echo ""
    read -p "Choose log type: " log_choice
    
    case $log_choice in
        1)
            print_status "Application logs:"
            tail -f data/logs/app.log
            ;;
        2)
            print_status "PM2 logs:"
            pm2 logs web-tracking
            ;;
        3)
            print_status "System service logs:"
            sudo journalctl -u web-tracking -f
            ;;
        4)
            print_status "Recent application logs:"
            tail -20 data/logs/app.log
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to update application
update_application() {
    print_status "Updating application..."
    cd /home/ubuntu/Web_tracking_ASIN_Amazon
    
    print_status "Pulling latest changes..."
    git pull origin main
    
    print_status "Installing dependencies..."
    npm install
    pip3 install -r python/requirements.txt
    
    print_status "Restarting service..."
    sudo systemctl restart web-tracking
    
    print_success "Application updated and restarted"
}

# Function to monitor resources
monitor_resources() {
    print_status "System Resources:"
    echo ""
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    
    echo "Memory Usage:"
    free -h | grep Mem | awk '{print $3 "/" $2}'
    
    echo "Disk Usage:"
    df -h / | tail -1 | awk '{print $5}'
    
    echo "PM2 Memory Usage:"
    pm2 status
}

# Function to check ports
check_ports() {
    print_status "Checking open ports..."
    echo ""
    echo "Port 3000 status:"
    netstat -tlnp | grep :3000 || echo "Port 3000 not listening"
    
    echo ""
    echo "Firewall status:"
    sudo ufw status
}

# Function to get public IP
get_public_ip() {
    print_status "Getting public IP..."
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    if [ -z "$PUBLIC_IP" ]; then
        print_warning "Could not get public IP"
        PUBLIC_IP="YOUR_EC2_IP"
    else
        print_success "Public IP: $PUBLIC_IP"
        echo "Application URL: http://$PUBLIC_IP:3000"
        echo "Health Check: http://$PUBLIC_IP:3000/health"
    fi
}

# Function to test application
test_application() {
    print_status "Testing application..."
    
    # Test local
    if curl -s http://localhost:3000/health > /dev/null; then
        print_success "Application is accessible locally"
    else
        print_error "Application is not accessible locally"
    fi
    
    # Test external
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    if [ ! -z "$PUBLIC_IP" ]; then
        if curl -s --connect-timeout 5 http://$PUBLIC_IP:3000/health > /dev/null; then
            print_success "Application is accessible from internet"
            echo "🌐 Access URL: http://$PUBLIC_IP:3000"
        else
            print_error "Application is not accessible from internet"
            echo "Check Security Group in AWS Console"
        fi
    fi
}

# Main menu loop
while true; do
    show_menu
    
    case $choice in
        1)
            start_service
            ;;
        2)
            stop_service
            ;;
        3)
            restart_service
            ;;
        4)
            check_status
            ;;
        5)
            view_logs
            ;;
        6)
            update_application
            ;;
        7)
            monitor_resources
            ;;
        8)
            check_ports
            ;;
        9)
            get_public_ip
            ;;
        10)
            test_application
            ;;
        0)
            print_status "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done 