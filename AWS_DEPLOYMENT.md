# AWS Deployment Guide

Hướng dẫn deploy Web Tracking ASIN Amazon lên AWS EC2 và mở port ra bên ngoài.

## 🚀 Quick Deployment

### **Step 1: Launch EC2 Instance**

1. **Login to AWS Console**
   - Go to: https://console.aws.amazon.com
   - Navigate to EC2 service

2. **Launch Instance**
   - Click "Launch Instance"
   - Choose "Ubuntu Server 22.04 LTS"
   - Select instance type: `t2.micro` (free tier) or `t2.small`
   - Configure Security Group (see Step 2)

### **Step 2: Configure Security Group**

1. **Create Security Group**
   - Name: `web-tracking-sg`
   - Description: `Security group for Web Tracking ASIN Amazon`

2. **Add Inbound Rules**
   ```
   Type        Port    Source
   SSH         22      0.0.0.0/0
   HTTP        80      0.0.0.0/0
   HTTPS       443     0.0.0.0/0
   Custom TCP  3000    0.0.0.0/0
   ```

3. **Add Outbound Rules**
   ```
   Type    Port    Destination
   All     0-65535 0.0.0.0/0
   ```

### **Step 3: Connect to EC2**

```bash
# Connect via SSH
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Or if using AWS Systems Manager Session Manager
aws ssm start-session --target i-1234567890abcdef0
```

### **Step 4: Install Application**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl wget git build-essential

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Python
sudo apt install -y python3 python3-pip

# Install Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable

# Install system dependencies
sudo apt install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1
```

### **Step 5: Deploy Application**

```bash
# Clone repository
git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
cd Web_tracking_ASIN_Amazon

# Install dependencies
npm install
pip3 install -r python/requirements.txt

# Create directories
mkdir -p data/logs data/database
```

### **Step 6: Configure Firewall**

```bash
# Run firewall setup script
sudo chmod +x setup-firewall.sh
./setup-firewall.sh

# Or manually configure ufw
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000
sudo ufw status
```

### **Step 7: Start Application**

```bash
# Start production server
npm run start:prod

# Or run in background
nohup npm run start:prod > app.log 2>&1 &

# Check if running
ps aux | grep node
netstat -tlnp | grep 3000
```

## 🌐 Access Application

### **Get EC2 Public IP**
```bash
# From EC2 instance
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Or check in AWS Console
# EC2 Dashboard > Instances > Your Instance > Public IPv4 address
```

### **Access URLs**
```
Application: http://YOUR_EC2_IP:3000
Health Check: http://YOUR_EC2_IP:3000/health
```

## 🔧 Production Setup

### **1. Using PM2 (Recommended)**

```bash
# Install PM2
sudo npm install -g pm2

# Start application with PM2
pm2 start server-production.js --name "web-tracking"

# Save PM2 configuration
pm2 save
pm2 startup

# Check status
pm2 status
pm2 logs web-tracking
```

### **2. Using Systemd Service**

```bash
# Create service file
sudo nano /etc/systemd/system/web-tracking.service
```

```ini
[Unit]
Description=Web Tracking ASIN Amazon
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/Web_tracking_ASIN_Amazon
ExecStart=/usr/bin/node server-production.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable web-tracking
sudo systemctl start web-tracking
sudo systemctl status web-tracking
```

## 🔍 Monitoring & Troubleshooting

### **Check Application Status**
```bash
# Check if port is listening
sudo netstat -tlnp | grep 3000

# Check firewall status
sudo ufw status

# Check application logs
tail -f data/logs/app.log

# Check system resources
htop
df -h
free -h
```

### **Check Security Group**
```bash
# From AWS Console
# EC2 > Security Groups > web-tracking-sg
# Verify inbound rules include port 3000
```

### **Common Issues**

#### **Port 3000 not accessible**
```bash
# Check if application is running
ps aux | grep node

# Check if port is open
sudo netstat -tlnp | grep 3000

# Check firewall
sudo ufw status

# Restart application
pm2 restart web-tracking
# or
sudo systemctl restart web-tracking
```

#### **Chrome not found**
```bash
# Reinstall Chrome
sudo apt update
sudo apt install -y google-chrome-stable

# Check Chrome installation
google-chrome --version
```

#### **Permission denied**
```bash
# Fix permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/Web_tracking_ASIN_Amazon
chmod +x setup-firewall.sh
```

## 📊 Performance Optimization

### **1. Increase Swap Memory**
```bash
# Create swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### **2. Optimize Node.js**
```bash
# Set Node.js options
export NODE_OPTIONS="--max-old-space-size=512"

# Or in PM2 ecosystem
pm2 start server-production.js --name "web-tracking" --node-args="--max-old-space-size=512"
```

### **3. Monitor Resources**
```bash
# Install monitoring tools
sudo apt install -y htop iotop

# Monitor in real-time
htop
iotop
```

## 🔒 Security Considerations

### **1. Use HTTPS (Optional)**
```bash
# Install nginx as reverse proxy
sudo apt install -y nginx

# Configure nginx
sudo nano /etc/nginx/sites-available/web-tracking
```

```nginx
server {
    listen 80;
    server_name YOUR_EC2_IP;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/web-tracking /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### **2. Regular Updates**
```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Update Node.js dependencies
npm update

# Update Python dependencies
pip3 list --outdated
pip3 install --upgrade -r python/requirements.txt
```

## 📈 Scaling

### **1. Load Balancer**
- Use AWS Application Load Balancer
- Configure target group for port 3000
- Enable health checks

### **2. Auto Scaling Group**
- Create launch template
- Configure auto scaling policies
- Set up CloudWatch alarms

### **3. Database Migration**
- Consider using RDS for production
- Implement database backups
- Set up monitoring

## 🎯 Success Checklist

- ✅ EC2 instance launched
- ✅ Security group configured
- ✅ Application deployed
- ✅ Firewall configured
- ✅ Application accessible from internet
- ✅ Monitoring set up
- ✅ Logs configured
- ✅ Backup strategy in place

**Your application is now accessible from anywhere in the world!** 🌍 