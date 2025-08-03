#!/bin/bash

echo "🔄 Auto Restart Setup Script"
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

print_status "Setting up auto restart on reboot..."

# Enable systemd service
print_status "Enabling systemd service..."
systemctl enable web-tracking
print_success "Service enabled for auto-start"

# Save PM2 startup configuration
print_status "Setting up PM2 startup..."
cd /home/ubuntu/Web_tracking_ASIN_Amazon
pm2 save
pm2 startup
print_success "PM2 startup configured"

# Create cron job for health check and auto restart
print_status "Creating health check cron job..."
cat > /etc/cron.d/web-tracking-health << 'EOF'
# Health check every 5 minutes
*/5 * * * * ubuntu /home/ubuntu/Web_tracking_ASIN_Amazon/health-check.sh
EOF
print_success "Cron job created"

# Create health check script
print_status "Creating health check script..."
cat > /home/ubuntu/Web_tracking_ASIN_Amazon/health-check.sh << 'EOF'
#!/bin/bash

# Health check script
APP_URL="http://localhost:3000/health"
LOG_FILE="/home/ubuntu/Web_tracking_ASIN_Amazon/data/logs/health-check.log"

# Check if application is responding
if ! curl -s --connect-timeout 10 "$APP_URL" > /dev/null; then
    echo "$(date): Application not responding, restarting..." >> "$LOG_FILE"
    
    # Restart the service
    sudo systemctl restart web-tracking
    
    # Wait for restart
    sleep 10
    
    # Check again
    if curl -s --connect-timeout 10 "$APP_URL" > /dev/null; then
        echo "$(date): Application restarted successfully" >> "$LOG_FILE"
    else
        echo "$(date): Application restart failed" >> "$LOG_FILE"
    fi
else
    echo "$(date): Application is healthy" >> "$LOG_FILE"
fi
EOF

chmod +x /home/ubuntu/Web_tracking_ASIN_Amazon/health-check.sh
print_success "Health check script created"

# Create log rotation
print_status "Setting up log rotation..."
cat > /etc/logrotate.d/web-tracking << 'EOF'
/home/ubuntu/Web_tracking_ASIN_Amazon/data/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
    postrotate
        systemctl reload web-tracking
    endscript
}
EOF
print_success "Log rotation configured"

# Create monitoring script
print_status "Creating monitoring script..."
cat > /home/ubuntu/Web_tracking_ASIN_Amazon/monitor.sh << 'EOF'
#!/bin/bash

echo "📊 Web Tracking ASIN Amazon - System Monitor"
echo "==============================================="

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="YOUR_EC2_IP"
fi

echo "🌐 Public IP: $PUBLIC_IP"
echo "🔗 Application URL: http://$PUBLIC_IP:3000"
echo ""

# Service status
echo "🔧 Service Status:"
if systemctl is-active --quiet web-tracking; then
    echo "✅ Service is running"
else
    echo "❌ Service is not running"
fi

# PM2 status
echo ""
echo "📊 PM2 Status:"
pm2 status

# System resources
echo ""
echo "💻 System Resources:"
echo "CPU Usage: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)"
echo "Memory Usage: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"

# Port status
echo ""
echo "🔌 Port Status:"
if netstat -tlnp | grep :3000 > /dev/null; then
    echo "✅ Port 3000 is listening"
else
    echo "❌ Port 3000 is not listening"
fi

# Application health
echo ""
echo "🏥 Application Health:"
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Application is healthy"
else
    echo "❌ Application is not responding"
fi

echo ""
echo "📋 Recent Logs:"
tail -5 /home/ubuntu/Web_tracking_ASIN_Amazon/data/logs/app.log
EOF

chmod +x /home/ubuntu/Web_tracking_ASIN_Amazon/monitor.sh
print_success "Monitoring script created"

# Set up automatic updates
print_status "Setting up automatic updates..."
cat > /etc/cron.d/web-tracking-update << 'EOF'
# Auto update every day at 2 AM
0 2 * * * ubuntu /home/ubuntu/Web_tracking_ASIN_Amazon/auto-update.sh
EOF
print_success "Auto update cron job created"

# Create auto update script
print_status "Creating auto update script..."
cat > /home/ubuntu/Web_tracking_ASIN_Amazon/auto-update.sh << 'EOF'
#!/bin/bash

LOG_FILE="/home/ubuntu/Web_tracking_ASIN_Amazon/data/logs/auto-update.log"

echo "$(date): Starting auto update..." >> "$LOG_FILE"

cd /home/ubuntu/Web_tracking_ASIN_Amazon

# Pull latest changes
git pull origin main >> "$LOG_FILE" 2>&1

# Install dependencies
npm install >> "$LOG_FILE" 2>&1
pip3 install -r python/requirements.txt >> "$LOG_FILE" 2>&1

# Restart service
sudo systemctl restart web-tracking >> "$LOG_FILE" 2>&1

echo "$(date): Auto update completed" >> "$LOG_FILE"
EOF

chmod +x /home/ubuntu/Web_tracking_ASIN_Amazon/auto-update.sh
print_success "Auto update script created"

# Set permissions
print_status "Setting permissions..."
chown -R ubuntu:ubuntu /home/ubuntu/Web_tracking_ASIN_Amazon
print_success "Permissions set"

echo ""
echo "🎉 Auto restart setup completed!"
echo "==============================================="
echo "📋 Features enabled:"
echo "- ✅ Auto-start on reboot"
echo "- ✅ Health check every 5 minutes"
echo "- ✅ Auto restart if application fails"
echo "- ✅ Log rotation"
echo "- ✅ Daily auto updates"
echo "- ✅ System monitoring"
echo ""
echo "🔧 Management commands:"
echo "- Check status: sudo systemctl status web-tracking"
echo "- View logs: tail -f data/logs/app.log"
echo "- Monitor: ./monitor.sh"
echo "- Manual update: ./auto-update.sh"
echo ""
echo "🌐 Your application will now:"
echo "- Start automatically on reboot"
echo "- Restart automatically if it crashes"
echo "- Update automatically every day at 2 AM"
echo "- Monitor system health" 