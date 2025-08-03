# Convert PuTTY key to OpenSSH format
Write-Host "🔑 Converting PuTTY key to OpenSSH format..."

# Check if PuTTYgen is available
$puttygenPath = "C:\Program Files\PuTTY\puttygen.exe"
if (Test-Path $puttygenPath) {
    Write-Host "✅ Found PuTTYgen at: $puttygenPath"
} else {
    Write-Host "❌ PuTTYgen not found. Please install PuTTY or provide path."
    Write-Host "Download from: https://www.putty.org/"
    exit 1
}

# Convert key
$ppkFile = "d:\AWS\ubuntu-key.ppk"
$pemFile = "d:\AWS\ubuntu-key.pem"

Write-Host "🔄 Converting $ppkFile to $pemFile..."

& $puttygenPath $ppkFile -O private-openssh -o $pemFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Key converted successfully!"
    
    # Set proper permissions
    Write-Host "🔒 Setting proper permissions..."
    icacls $pemFile /inheritance:r /grant:r "$env:USERNAME:F"
    
    Write-Host "🎉 Ready to use OpenSSH key: $pemFile"
    Write-Host "📋 SSH command: ssh -i `"$pemFile`" ubuntu@3.27.173.226"
} else {
    Write-Host "❌ Conversion failed!"
} 