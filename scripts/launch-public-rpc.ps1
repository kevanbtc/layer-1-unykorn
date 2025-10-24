# ============================================
# UNYKORN SOVEREIGN L1 - PUBLIC RPC LAUNCHER
# ============================================
# This script downloads cloudflared and exposes your sovereign chain to the world
# No account or configuration required - instant public HTTPS URL

Write-Host "`nLAUNCHING PUBLIC RPC FOR UNYKORN SOVEREIGN L1..." -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Check if cloudflared already exists
$cloudflaredPath = ".\cloudflared.exe"
if (-not (Test-Path $cloudflaredPath)) {
    Write-Host "Downloading Cloudflare Tunnel (cloudflared)..." -ForegroundColor Yellow
    
    # Download cloudflared for Windows
    $downloadUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $cloudflaredPath -UseBasicParsing
        Write-Host "Downloaded cloudflared successfully!`n" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download cloudflared: $_" -ForegroundColor Red
        Write-Host "`nManual installation option:" -ForegroundColor Yellow
        Write-Host "   1. Download from: https://github.com/cloudflare/cloudflared/releases" -ForegroundColor Yellow
        Write-Host "   2. Save as: cloudflared.exe in this directory" -ForegroundColor Yellow
        Write-Host "   3. Run this script again`n" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "cloudflared.exe already exists`n" -ForegroundColor Green
}

# Verify RPC endpoint is running
Write-Host "Checking if Sovereign L1 is running..." -ForegroundColor Yellow
try {
    $body = '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
    $response = Invoke-RestMethod -Uri http://127.0.0.1:8555 -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    $chainId = [Convert]::ToInt32($response.result, 16)
    
    if ($chainId -eq 7777) {
        Write-Host "Sovereign L1 (ChainID $chainId) is running on http://127.0.0.1:8555`n" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Chain is running but ChainID is $chainId (expected 7777)`n" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Cannot connect to http://127.0.0.1:8555" -ForegroundColor Red
    Write-Host "   Make sure your sovereign validator is running:" -ForegroundColor Yellow
    Write-Host "   docker-compose -f docker/docker-compose.sovereign.yml up -d`n" -ForegroundColor Yellow
    exit 1
}

# Get current block height
try {
    $body = '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
    $response = Invoke-RestMethod -Uri http://127.0.0.1:8555 -Method Post -Body $body -ContentType "application/json"
    $blockNum = [Convert]::ToInt32($response.result, 16)
    Write-Host "Current Block Height: $blockNum" -ForegroundColor Cyan
} catch {
    $blockNum = "Unknown"
}

# Launch cloudflared tunnel
Write-Host "`nLAUNCHING PUBLIC TUNNEL...`n" -ForegroundColor Magenta
Write-Host "Cloudflared is starting (this takes 5-10 seconds)..." -ForegroundColor Yellow
Write-Host "Once the public URL appears, your chain is LIVE to the world!`n" -ForegroundColor Yellow

Write-Host "===================================================" -ForegroundColor Green
Write-Host "  UNYKORN SOVEREIGN L1 - GOING GLOBAL" -ForegroundColor Green
Write-Host "===================================================`n" -ForegroundColor Green

Write-Host "INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "   1. Copy the HTTPS URL that appears below" -ForegroundColor White
Write-Host "   2. Open MetaMask -> Settings -> Networks -> Add Network" -ForegroundColor White
Write-Host "   3. Use the public URL as your RPC endpoint" -ForegroundColor White
Write-Host "   4. Share the URL with anyone who wants to connect`n" -ForegroundColor White

Write-Host "SECURITY NOTES:" -ForegroundColor Yellow
Write-Host "   - This tunnel is FREE and has no bandwidth limits" -ForegroundColor White
Write-Host "   - Cloudflare provides automatic HTTPS encryption" -ForegroundColor White
Write-Host "   - The URL will change if you restart the tunnel" -ForegroundColor White
Write-Host "   - For permanent URLs, create a named tunnel (see docs)`n" -ForegroundColor White

Write-Host "PRESS CTRL+C TO STOP THE TUNNEL`n" -ForegroundColor Red
Write-Host "------------------------------------------------`n" -ForegroundColor Cyan

# Run cloudflared tunnel (this will block and show the public URL)
& $cloudflaredPath tunnel --url http://localhost:8555
