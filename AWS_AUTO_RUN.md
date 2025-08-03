# AWS Auto Run Guide

Hướng dẫn sử dụng scripts tự động chạy trên AWS Ubuntu.

## 🚀 Quick Start

### **Step 1: Deploy Application**
```bash
# SSH vào EC2 instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Chạy auto deploy script
sudo chmod +x aws-auto-deploy.sh
./aws-auto-deploy.sh
```

### **Step 2: Setup Auto Restart**
```bash
# Setup auto restart và monitoring
sudo chmod +x setup-auto-restart.sh
./setup-auto-restart.sh
```

## 📋 Scripts Overview

### **1. `aws-auto-deploy.sh` - Auto Deploy Script**
**Chức năng:**
- ✅ Cài đặt tất cả dependencies (Node.js, Python, Chrome)
- ✅ Cấu hình firewall
- ✅ Clone repository
- ✅ Cài đặt dependencies
- ✅ Tạo PM2 ecosystem
- ✅ Tạo systemd service
- ✅ Start service tự động

**Cách sử dụng:**
```bash
sudo ./aws-auto-deploy.sh
```

### **2. `manage-service.sh` - Service Management**
**Chức năng:**
- ✅ Start/Stop/Restart service
- ✅ Check status
- ✅ View logs
- ✅ Update application
- ✅ Monitor resources
- ✅ Check ports
- ✅ Test application

**Cách sử dụng:**
```bash
./manage-service.sh
```

### **3. `setup-auto-restart.sh` - Auto Restart Setup**
**Chức năng:**
- ✅ Enable auto-start on reboot
- ✅ Health check every 5 minutes
- ✅ Auto restart if application fails
- ✅ Log rotation
- ✅ Daily auto updates
- ✅ System monitoring

**Cách sử dụng:**
```bash
sudo ./setup-auto-restart.sh
```

### **4. `monitor.sh` - System Monitor**
**Chức năng:**
- ✅ Service status
- ✅ PM2 status
- ✅ System resources
- ✅ Port status
- ✅ Application health
- ✅ Recent logs

**Cách sử dụng:**
```bash
./monitor.sh
```

## 🔧 Management Commands

### **Service Management**
```bash
# Check service status
sudo systemctl status web-tracking

# Start service
sudo systemctl start web-tracking

# Stop service
sudo systemctl stop web-tracking

# Restart service
sudo systemctl restart web-tracking

# Enable auto-start
sudo systemctl enable web-tracking
```

### **PM2 Management**
```bash
# Check PM2 status
pm2 status

# View PM2 logs
pm2 logs web-tracking

# Restart PM2 process
pm2 restart web-tracking

# Stop PM2 process
pm2 stop web-tracking

# Save PM2 configuration
pm2 save
```

### **Logs Management**
```bash
# Application logs
tail -f data/logs/app.log

# PM2 logs
pm2 logs web-tracking

# System service logs
sudo journalctl -u web-tracking -f

# Health check logs
tail -f data/logs/health-check.log

# Auto update logs
tail -f data/logs/auto-update.log
```

### **Monitoring**
```bash
# System monitor
./monitor.sh

# Check ports
netstat -tlnp | grep 3000

# Check firewall
sudo ufw status

# Check resources
htop
free -h
df -h
```

## 🔄 Auto Features

### **1. Auto Start on Reboot**
- Service tự động start khi reboot
- PM2 tự động restore processes
- Application sẵn sàng sau reboot

### **2. Health Check**
- Kiểm tra mỗi 5 phút
- Tự động restart nếu application crash
- Log health check status

### **3. Auto Update**
- Update hàng ngày lúc 2 AM
- Pull latest code từ GitHub
- Install dependencies
- Restart service

### **4. Log Rotation**
- Rotate logs hàng ngày
- Giữ logs 7 ngày
- Compress old logs
- Reload service sau rotation

## 📊 Monitoring Dashboard

### **System Resources**
```bash
# CPU Usage
top -bn1 | grep 'Cpu(s)'

# Memory Usage
free -h

# Disk Usage
df -h

# PM2 Memory
pm2 status
```

### **Application Health**
```bash
# Health check
curl http://localhost:3000/health

# Application status
systemctl is-active web-tracking

# Port status
netstat -tlnp | grep :3000
```

## 🐛 Troubleshooting

### **Service Not Starting**
```bash
# Check service status
sudo systemctl status web-tracking

# Check logs
sudo journalctl -u web-tracking -f

# Check PM2
pm2 status
pm2 logs web-tracking

# Manual start
cd /home/ubuntu/Web_tracking_ASIN_Amazon
npm run start:prod
```

### **Port Not Accessible**
```bash
# Check if port is listening
netstat -tlnp | grep :3000

# Check firewall
sudo ufw status

# Check security group in AWS Console
# EC2 > Security Groups > Inbound rules
```

### **Application Not Responding**
```bash
# Check application logs
tail -f data/logs/app.log

# Check health
curl http://localhost:3000/health

# Restart service
sudo systemctl restart web-tracking

# Check PM2
pm2 restart web-tracking
```

### **High Resource Usage**
```bash
# Check system resources
htop
free -h
df -h

# Check PM2 memory
pm2 status

# Restart if needed
pm2 restart web-tracking
```

## 🔒 Security

### **Firewall Rules**
```bash
# Check firewall status
sudo ufw status

# Allow specific ports
sudo ufw allow 3000
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
```

### **Service Permissions**
```bash
# Set correct permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/Web_tracking_ASIN_Amazon
chmod +x *.sh
```

## 📈 Performance Optimization

### **Memory Optimization**
```bash
# Set Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=512"

# PM2 with memory limit
pm2 start ecosystem.config.js --node-args="--max-old-space-size=512"
```

### **Swap Memory**
```bash
# Create swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 🎯 Success Checklist

- ✅ Application deployed successfully
- ✅ Service starts automatically
- ✅ Health check working
- ✅ Auto restart configured
- ✅ Logs rotating properly
- ✅ Monitoring active
- ✅ Accessible from internet
- ✅ Auto updates enabled

## 🌐 Access URLs

```
Application: http://YOUR_EC2_IP:3000
Health Check: http://YOUR_EC2_IP:3000/health
```

**Your application is now fully automated and will run continuously!** 🚀 