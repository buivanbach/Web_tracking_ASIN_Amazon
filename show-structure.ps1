Write-Host "🌳 Web Ranking App - Project Structure" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Get project structure (excluding node_modules)
$structure = @"
📁 Web_RANKing/
├── 📄 package.json                    # Node.js dependencies & scripts
├── 📄 package-lock.json              # Locked dependencies
├── 📄 server.js                      # Main server entry point
├── 📄 .gitignore                     # Git ignore rules
├── 📄 README.md                      # Project documentation
├── 📄 setup.ps1                      # Windows setup script
├── 📄 run.ps1                        # Windows run script
│
├── 📁 src/                           # Backend source code
│   ├── 📁 config/
│   │   └── 📄 database.js            # Database configuration
│   ├── 📁 controllers/
│   │   ├── 📄 ProductController.js   # Product API endpoints
│   │   └── 📄 SettingsController.js  # Settings API endpoints
│   ├── 📁 models/
│   │   └── 📄 Product.js             # Database operations
│   ├── 📁 routes/
│   │   └── 📄 index.js               # Route definitions
│   ├── 📁 services/
│   │   ├── 📄 CrawlerService.js      # Crawling business logic
│   │   └── 📄 ServiceManager.js      # Service dependency injection
│   └── 📁 utils/
│       └── 📄 logger.js              # Centralized logging
│
├── 📁 public/                        # Frontend files
│   ├── 📄 index.html                 # Main HTML page
│   ├── 📄 script.js                  # Frontend JavaScript
│   └── 📄 styles.css                 # Frontend styles
│
├── 📁 python/                        # Python crawler
│   ├── 📄 crawl_and_update_fixed.py  # Main crawler script
│   └── 📄 requirements.txt           # Python dependencies
│
└── 📁 data/                          # Application data
    ├── 📁 database/
    │   └── 📄 database.db            # SQLite database
    └── 📁 logs/
        └── 📄 app.log                # Application logs
"@

Write-Host $structure -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 File Count Summary:" -ForegroundColor Yellow
Write-Host "- Backend files: 8" -ForegroundColor White
Write-Host "- Frontend files: 3" -ForegroundColor White
Write-Host "- Python files: 2" -ForegroundColor White
Write-Host "- Configuration files: 4" -ForegroundColor White
Write-Host "- Data files: 2" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Key Features:" -ForegroundColor Yellow
Write-Host "- Modular MVC architecture" -ForegroundColor White
Write-Host "- Automated Amazon product crawling" -ForegroundColor White
Write-Host "- Real-time UI updates" -ForegroundColor White
Write-Host "- Persistent crawl schedule" -ForegroundColor White
Write-Host "- One-command setup & run" -ForegroundColor White 