# Web Ranking App - Run Script
# Chạy script này để start application

Write-Host "🚀 Web Ranking App - Starting..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Add Node.js to PATH if not already there
if (!(Get-Command "node" -ErrorAction SilentlyContinue)) {
    $env:PATH += ";C:\Program Files\nodejs"
    Write-Host "✅ Added Node.js to PATH" -ForegroundColor Green
}

# Check if Node.js is available
if (!(Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js not found. Please run setup first: .\setup.ps1" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if npm is available
if (!(Get-Command "npm" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ npm not found. Please run setup first: .\setup.ps1" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Python is available
if (!(Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Python not found. Please run setup first: .\setup.ps1" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ All dependencies found" -ForegroundColor Green
Write-Host ""

# Check if port 3000 is in use
$portInUse = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "⚠️  Port 3000 is already in use" -ForegroundColor Yellow
    Write-Host "💡 The application might already be running" -ForegroundColor Yellow
    Write-Host "🌐 Try opening: http://localhost:3000" -ForegroundColor Cyan
    Write-Host ""
    $choice = Read-Host "Do you want to kill the existing process? (Y/N)"
    if ($choice -eq "Y" -or $choice -eq "y") {
        $portInUse | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
        Write-Host "✅ Killed existing process" -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
}

Write-Host ""
Write-Host "📋 Application Information:" -ForegroundColor Yellow
Write-Host "- URL: http://localhost:3000" -ForegroundColor White
Write-Host "- Logs: data/logs/app.log" -ForegroundColor White
Write-Host "- Database: data/database/database.db" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Commands:" -ForegroundColor Yellow
Write-Host "- Stop: Ctrl+C" -ForegroundColor White
Write-Host "- Restart: Run this script again" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Usage:" -ForegroundColor Yellow
Write-Host "1. Open browser: http://localhost:3000" -ForegroundColor White
Write-Host "2. Go to URL Manager tab" -ForegroundColor White
Write-Host "3. Add Amazon URLs" -ForegroundColor White
Write-Host "4. Monitor crawling progress" -ForegroundColor White
Write-Host ""
Write-Host "⏳ Starting server..." -ForegroundColor Green
Write-Host ""

# Start the application
npm start 