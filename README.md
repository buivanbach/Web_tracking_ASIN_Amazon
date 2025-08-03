# Web Tracking ASIN Amazon

A web application for tracking Amazon product rankings and ASINs with automated crawling.

## 🎯 Features

- **ASIN Tracking**: Monitor Amazon product ASINs and rankings
- **Automated Crawling**: Scheduled crawling with configurable intervals
- **Real-time Updates**: Live UI updates during crawling process
- **Persistent Settings**: Crawl schedule saved to database
- **Modern UI**: Amazon-like product grid interface
- **Trending Analysis**: Identify products with rank improvements
- **URL Management**: Easy URL submission and management

## 🏗️ Architecture

**Modular MVC Structure:**
```
Web_RANKing/
├── src/                            # Backend source code
│   ├── config/database.js          # Database configuration
│   ├── controllers/                 # API controllers
│   ├── models/Product.js           # Database operations
│   ├── services/                   # Business logic services
│   ├── utils/logger.js             # Centralized logging
│   └── routes/index.js             # Route definitions
├── public/                         # Frontend files
├── python/                         # Python crawler
├── data/                           # Application data
├── setup.ps1                       # Windows setup script
├── run.ps1                         # Windows run script
└── server.js                       # Main server
```

## 🚀 Quick Start

### **Windows Setup**
```powershell
# Clone repository
git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
cd Web_tracking_ASIN_Amazon

# Auto setup
.\setup.ps1

# Run application
.\run.ps1
```

### **Ubuntu/Linux Setup**
```bash
# Clone repository
git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
cd Web_tracking_ASIN_Amazon

# Auto setup
chmod +x setup-ubuntu.sh
./setup-ubuntu.sh

# Run application
chmod +x run-ubuntu.sh
./run-ubuntu.sh
```

### **AWS Ubuntu Setup**
```bash
# SSH vào EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Clone và auto deploy
git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
cd Web_tracking_ASIN_Amazon

# Auto deploy
sudo chmod +x aws-auto-deploy.sh
./aws-auto-deploy.sh

# Setup auto restart
sudo chmod +x setup-auto-restart.sh
./setup-auto-restart.sh
```

## 🌐 Access URLs

### **Local Development**
```
Application: http://localhost:3000
Health Check: http://localhost:3000/health
```

### **AWS Production**
```
Application: http://YOUR_EC2_IP:3000
Health Check: http://YOUR_EC2_IP:3000/health
```

## 🔧 Management Commands

### **Windows**
```powershell
# Start application
.\run.ps1

# Or manually
npm start
```

### **Ubuntu/Linux**
```bash
# Start application
./run-ubuntu.sh

# Or manually
npm start
```

### **AWS Ubuntu**
```bash
# Check service status
sudo systemctl status web-tracking

# Start/Stop/Restart service
sudo systemctl start web-tracking
sudo systemctl stop web-tracking
sudo systemctl restart web-tracking

# View logs
tail -f data/logs/app.log

# Monitor system
./monitor.sh
```

## ✨ Features

- **ASIN Tracking**: Monitor Amazon product ASINs and rankings
- **Automated Crawling**: Scheduled crawling with configurable intervals
- **Real-time Updates**: Live UI updates during crawling process
- **Persistent Settings**: Crawl schedule saved to database
- **Modern UI**: Amazon-like product grid interface
- **Trending Analysis**: Identify products with rank improvements
- **URL Management**: Easy URL submission and management

## 🚀 AWS Deployment

### **Quick Deploy**
```bash
# SSH vào EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Auto deploy
git clone https://github.com/buivanbach/Web_tracking_ASIN_Amazon.git
cd Web_tracking_ASIN_Amazon
sudo chmod +x aws-auto-deploy.sh
./aws-auto-deploy.sh
```

### **Security Group Configuration**
```
Type        Port    Source
SSH         22      0.0.0.0/0
HTTP        80      0.0.0.0/0
HTTPS       443     0.0.0.0/0
Custom TCP  3000    0.0.0.0/0  ← Required for application
```

### **Auto Features**
- ✅ Auto-start on reboot
- ✅ Health check every 5 minutes
- ✅ Auto restart if application fails
- ✅ Daily auto updates
- ✅ Log rotation
- ✅ System monitoring

## 🔧 Technology Stack

- **Backend**: Node.js + Express
- **Database**: SQLite
- **Frontend**: HTML/CSS/JavaScript
- **Crawler**: Python + Selenium + EasyOCR
- **Scheduling**: node-cron

## 📊 API Endpoints

- `GET /api/products` - Get all products with trending data
- `GET /api/crawl-status` - Get crawl status for URLs
- `POST /api/crawl` - Start crawling URLs
- `DELETE /api/products/:id` - Delete a product
- `POST /api/settings/crawl-interval` - Update crawl interval
- `POST /api/settings/clear-database` - Clear all data

## 🎯 Key Improvements

### **Modular Architecture:**
- **Separation of Concerns**: Controllers, Models, Services, Utils
- **Maintainability**: Small, focused files
- **Testability**: Easy to unit test
- **Scalability**: Easy to extend

### **Database Layer:**
```javascript
// Promise-based operations
await db.run(sql, params);
await db.get(sql, params);
await db.all(sql, params);
```

### **Centralized Logging:**
```javascript
logger.info('Message');
logger.error('Error message');
logger.warn('Warning message');
```

### **Clean Controllers:**
```javascript
class ProductController {
    async getAllProducts(req, res) { ... }
    async crawlUrls(req, res) { ... }
    async deleteProduct(req, res) { ... }
}
```

## 🔍 Usage

### **Adding Products:**
1. Go to "URL Manager" tab
2. Paste Amazon product URLs (one per line)
3. Click "Add URLs" to start crawling
4. Monitor progress in real-time

### **Viewing Products:**
- **Products Tab**: View all tracked products
- **Trending Tab**: View products with >10% rank improvement
- **Settings Tab**: Configure crawl intervals and clear database

### **Features:**
- **Real-time Updates**: UI updates as products are crawled
- **Rank History**: Track last 5 rank changes per product
- **Trending Detection**: Automatic identification of improving products
- **Error Handling**: Graceful handling of failed crawls
- **Responsive Design**: Works on desktop and mobile

## 🛠️ Configuration

### **Crawl Interval:**
- Default: 2 hours
- Range: 1-24 hours
- Configure via Settings tab

### **Database:**
- SQLite database file: `database.db`
- Automatic schema creation
- Rank history tracking

## 🔧 Troubleshooting

### **Common Issues:**

1. **Node.js not found:**
   ```bash
   $env:PATH += ";C:\Program Files\nodejs"
   ```

2. **Python dependencies missing:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Database errors:**
   - Delete `database.db` to reset
   - Check logs in `logs/app.log`

### **Logs:**
- Application logs: `logs/app.log`
- Real-time monitoring available

## 📝 Development

### **Adding New Features:**
1. **Backend**: Add controllers in `src/controllers/`
2. **Database**: Update models in `src/models/`
3. **Frontend**: Modify files in `public/`
4. **Crawler**: Update `crawl_and_update_fixed.py`

### **Code Structure:**
- **MVC Architecture**: Controllers, Models, Views
- **Modular Design**: Separate concerns
- **Error Handling**: Comprehensive logging
- **Async/Await**: Modern JavaScript patterns

## 🧪 Testing Setup

After running the setup script, you can test if everything is working:

```bash
npm run test-setup
```

This will check:
- ✅ Node.js and npm versions
- ✅ Python and pip versions
- ✅ Project structure
- ✅ Required files and directories
- ✅ Dependencies installation

## 📄 License

MIT License - feel free to use and modify as needed. 