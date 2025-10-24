# ========================================
# CLOUDFLARE TUNNEL SERVICE INSTALLER
# ========================================
# This script installs cloudflared as a Windows Service
# using the token from your Cloudflare Zero Trust dashboard

Write-Host "`n=== CLOUDFLARE TUNNEL SERVICE INSTALLER ===" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must run as Administrator!" -ForegroundColor Red
    Write-Host "`nTo run as Administrator:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor White
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "  3. Navigate to: cd 'C:\Users\Kevan\layer 1 build'" -ForegroundColor White
    Write-Host "  4. Run: .\scripts\install-cloudflared-service.ps1`n" -ForegroundColor White
    exit 1
}

Write-Host "Running as Administrator: YES`n" -ForegroundColor Green

# Check if cloudflared.exe exists
if (-not (Test-Path ".\cloudflared.exe")) {
    Write-Host "ERROR: cloudflared.exe not found!" -ForegroundColor Red
    Write-Host "Expected location: C:\Users\Kevan\layer 1 build\cloudflared.exe`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "cloudflared.exe found!`n" -ForegroundColor Green

# Prompt for token
Write-Host "=== TUNNEL TOKEN REQUIRED ===" -ForegroundColor Yellow
Write-Host "Go to your Cloudflare Zero Trust dashboard:" -ForegroundColor White
Write-Host "  https://one.dash.cloudflare.com/`n" -ForegroundColor Cyan

Write-Host "Navigate to: Networks > Tunnels > [Your Tunnel]" -ForegroundColor White
Write-Host "Copy the FULL service install command that looks like:" -ForegroundColor White
Write-Host "  cloudflared.exe service install eyJhIjoiMD... [very long token] ...`n" -ForegroundColor Gray
Write-Host "Note: This is NOT the 'tunnel run' command; it must be the long service install token." -ForegroundColor Yellow

Write-Host "Paste your FULL tunnel token (starts with eyJ):" -ForegroundColor Cyan
Write-Host "(Right-click to paste, then press Enter)`n" -ForegroundColor Yellow

$token = Read-Host "Token"

if ($token -eq "" -or $token.Length -lt 100) {
    Write-Host "`nERROR: Token appears invalid or incomplete!" -ForegroundColor Red
    Write-Host "Token should be 500+ characters long starting with 'eyJ'`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nToken received (length: $($token.Length) characters)" -ForegroundColor Green

# Check if service already exists
$service = Get-Service -Name "cloudflared" -ErrorAction SilentlyContinue

if ($service) {
    Write-Host "`nWARNING: cloudflared service already exists!" -ForegroundColor Yellow
    Write-Host "Current status: $($service.Status)" -ForegroundColor White
    Write-Host "`nDo you want to:" -ForegroundColor Cyan
    Write-Host "  1. Uninstall existing and reinstall (recommended)" -ForegroundColor White
    Write-Host "  2. Keep existing service" -ForegroundColor White
    
    $choice = Read-Host "`nChoice (1 or 2)"
    
    if ($choice -eq "1") {
        Write-Host "`nUninstalling existing service..." -ForegroundColor Yellow
        .\cloudflared.exe service uninstall
        Start-Sleep -Seconds 2
    } else {
        Write-Host "`nKeeping existing service.`n" -ForegroundColor Green
        exit 0
    }
}

# Install service with token
Write-Host "`nInstalling cloudflared as Windows Service..." -ForegroundColor Yellow

try {
    .\cloudflared.exe service install $token
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nSUCCESS! Service installed!" -ForegroundColor Green
        
        # Start or restart the service
        try {
            Write-Host "`nStarting cloudflared service..." -ForegroundColor Yellow
            Start-Service cloudflared -ErrorAction Stop
        } catch {
            Write-Host "Service wasn't running, attempting restart..." -ForegroundColor Yellow
            try {
                Restart-Service cloudflared -ErrorAction Stop
            } catch {
                Write-Host "Restart failed: $_" -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 3
        
        # Check status
        $service = Get-Service -Name "cloudflared"
        Write-Host "Service Status: $($service.Status)" -ForegroundColor Green
        
        Write-Host "`n=== TUNNEL IS NOW RUNNING AS A SERVICE ===" -ForegroundColor Green
        Write-Host "Your tunnel will automatically start on Windows boot!`n" -ForegroundColor Green
        
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Go to Cloudflare dashboard to see connector status" -ForegroundColor White
        Write-Host "  2. Configure Public Hostname (route traffic to localhost:8555)" -ForegroundColor White
        Write-Host "  3. Test your permanent URL!`n" -ForegroundColor White
        
        Write-Host "Useful commands:" -ForegroundColor Cyan
        Write-Host "  Stop service:    Stop-Service cloudflared" -ForegroundColor White
        Write-Host "  Start service:   Start-Service cloudflared" -ForegroundColor White
        Write-Host "  Restart:         Restart-Service cloudflared" -ForegroundColor White
        Write-Host "  Check status:    Get-Service cloudflared" -ForegroundColor White
        Write-Host "  Uninstall:       .\cloudflared.exe service uninstall`n" -ForegroundColor White

        # Optional: show helpful file locations if present
        $cfDir = Join-Path $env:USERPROFILE '.cloudflared'
        if (Test-Path $cfDir) {
            Write-Host "Config directory: $cfDir" -ForegroundColor DarkGray
            Get-ChildItem $cfDir | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor DarkGray }
            Write-Host ""
        }
        
        Write-Host "Internet → https://rpc.unykorn.org (Cloudflare) " -ForegroundColor Green
        Write-Host "         → cloudflared service on your PC " -ForegroundColor Green
        Write-Host "         → http://localhost:8555 (Besu RPC)" -ForegroundColor Green
        
        # Run test suite
        Write-Host "`nRunning test suite..." -ForegroundColor Yellow
        .\test-rpc-suite.ps1 -RpcUrl "http://127.0.0.1:8555"
        
    } else {
        Write-Host "`nERROR: Service installation failed!" -ForegroundColor Red
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Yellow
        Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
        Write-Host "  - Ensure you're pasting the SERVICE INSTALL token (long 'eyJ...' string)" -ForegroundColor White
        Write-Host "  - Run this script as Administrator" -ForegroundColor White
        Write-Host "  - Verify your tunnel shows up in Cloudflare Zero Trust > Networks > Tunnels" -ForegroundColor White
        Write-Host "  - If needed, uninstall and retry: .\\cloudflared.exe service uninstall" -ForegroundColor White
        Write-Host "" 
    }
    
} catch {
    Write-Host "`nERROR: $_`n" -ForegroundColor Red
}
