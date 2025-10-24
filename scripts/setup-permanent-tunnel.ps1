# ========================================
# CLOUDFLARE NAMED TUNNEL SETUP
# ========================================
# Upgrades from temporary quick tunnel to permanent named tunnel
# Result: Permanent URL that doesn't change on restart

Write-Host "`n=== CLOUDFLARE NAMED TUNNEL SETUP ===" -ForegroundColor Cyan
Write-Host "This will create a PERMANENT public RPC endpoint`n" -ForegroundColor Cyan

# Check if cloudflared exists
if (-not (Test-Path ".\cloudflared.exe")) {
    Write-Host "ERROR: cloudflared.exe not found!" -ForegroundColor Red
    Write-Host "Run launch-public-rpc.ps1 first to download it.`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "Current Setup:" -ForegroundColor Yellow
Write-Host "  Quick Tunnel: https://admissions-producing-cut-elephant.trycloudflare.com" -ForegroundColor White
Write-Host "  Status: WORKING but URL changes on restart`n" -ForegroundColor White

Write-Host "Upgrade Options:`n" -ForegroundColor Yellow

Write-Host "1. NAMED TUNNEL (Recommended - FREE & PERMANENT)" -ForegroundColor Green
Write-Host "   - Requires: Cloudflare account (free)" -ForegroundColor White
Write-Host "   - Requires: Domain name (e.g., unykorn.org, unykorn.xyz)" -ForegroundColor White
Write-Host "   - Result: https://rpc.unykorn.org (permanent forever)" -ForegroundColor White
Write-Host "   - Setup time: 15 minutes`n" -ForegroundColor White

Write-Host "2. KEEP QUICK TUNNEL (Current - FREE but TEMPORARY)" -ForegroundColor Yellow
Write-Host "   - No requirements" -ForegroundColor White
Write-Host "   - Result: URL changes every restart" -ForegroundColor White
Write-Host "   - Good for: Testing and demos`n" -ForegroundColor White

Write-Host "3. VPS DEPLOYMENT (Production - $4-20/month)" -ForegroundColor Cyan
Write-Host "   - Requires: DigitalOcean/AWS/Linode account" -ForegroundColor White
Write-Host "   - Result: Full control, custom domain, monitoring" -ForegroundColor White
Write-Host "   - Setup time: 2-3 hours`n" -ForegroundColor White

$choice = Read-Host "Enter choice (1, 2, or 3)"

switch ($choice) {
    "1" {
        Write-Host "`n=== SETTING UP NAMED TUNNEL ===" -ForegroundColor Green
        
        # Check if already logged in
        $configPath = "$env:USERPROFILE\.cloudflared"
        if (Test-Path "$configPath\cert.pem") {
            Write-Host "Already logged in to Cloudflare!`n" -ForegroundColor Green
        } else {
            Write-Host "`nStep 1: Login to Cloudflare" -ForegroundColor Yellow
            Write-Host "This will open a browser window..." -ForegroundColor White
            Write-Host "Press Enter to continue..." -ForegroundColor Cyan
            Read-Host
            
            .\cloudflared.exe login
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host "`nERROR: Login failed!" -ForegroundColor Red
                Write-Host "Make sure you have a Cloudflare account (sign up at https://cloudflare.com)`n" -ForegroundColor Yellow
                exit 1
            }
        }
        
        Write-Host "`nStep 2: Create Named Tunnel" -ForegroundColor Yellow
        $tunnelName = "unykorn-l1-rpc"
        Write-Host "Creating tunnel: $tunnelName..." -ForegroundColor White
        
        .\cloudflared.exe tunnel create $tunnelName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nERROR: Tunnel creation failed!" -ForegroundColor Red
            Write-Host "The tunnel might already exist. Try a different name.`n" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "`nStep 3: Configure DNS" -ForegroundColor Yellow
        Write-Host "Enter your domain name (e.g., unykorn.org):" -ForegroundColor Cyan
        $domain = Read-Host "Domain"
        
        if ($domain -eq "") {
            Write-Host "`nERROR: Domain required!" -ForegroundColor Red
            Write-Host "You need to own a domain. Register one at:" -ForegroundColor Yellow
            Write-Host "  - Namecheap: https://www.namecheap.com" -ForegroundColor White
            Write-Host "  - Cloudflare: https://www.cloudflare.com/products/registrar/" -ForegroundColor White
            Write-Host "  - GoDaddy: https://www.godaddy.com`n" -ForegroundColor White
            exit 1
        }
        
        $rpcDomain = "rpc.$domain"
        Write-Host "Setting up DNS: $rpcDomain..." -ForegroundColor White
        
        .\cloudflared.exe tunnel route dns $tunnelName $rpcDomain
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nWARNING: DNS setup failed!" -ForegroundColor Yellow
            Write-Host "This usually means the domain is not in your Cloudflare account." -ForegroundColor Yellow
            Write-Host "Manual steps:" -ForegroundColor Yellow
            Write-Host "  1. Add $domain to Cloudflare (free plan)" -ForegroundColor White
            Write-Host "  2. Update nameservers at your domain registrar" -ForegroundColor White
            Write-Host "  3. Wait for DNS propagation (5-60 minutes)" -ForegroundColor White
            Write-Host "  4. Run this script again`n" -ForegroundColor White
            exit 1
        }
        
        Write-Host "`nStep 4: Start Named Tunnel" -ForegroundColor Yellow
        Write-Host "Tunnel is starting..." -ForegroundColor White
        Write-Host "`nYour PERMANENT public RPC:" -ForegroundColor Green
        Write-Host "  https://$rpcDomain`n" -ForegroundColor Cyan
        
        Write-Host "Press CTRL+C to stop the tunnel`n" -ForegroundColor Red
        
        .\cloudflared.exe tunnel run $tunnelName
    }
    
    "2" {
        Write-Host "`n=== KEEPING QUICK TUNNEL ===" -ForegroundColor Yellow
        Write-Host "Restarting quick tunnel..." -ForegroundColor White
        Write-Host "Note: URL will change if you restart!`n" -ForegroundColor Yellow
        
        .\cloudflared.exe tunnel --url http://localhost:8555
    }
    
    "3" {
        Write-Host "`n=== VPS DEPLOYMENT ===" -ForegroundColor Cyan
        Write-Host "VPS deployment requires manual setup." -ForegroundColor White
        Write-Host "Full guide available in: PERMANENT_RPC_SETUP.md`n" -ForegroundColor White
        
        Write-Host "Quick summary:" -ForegroundColor Yellow
        Write-Host "  1. Create VPS (DigitalOcean $4/month recommended)" -ForegroundColor White
        Write-Host "  2. Install Docker + nginx" -ForegroundColor White
        Write-Host "  3. Deploy Besu validator" -ForegroundColor White
        Write-Host "  4. Configure SSL with Let's Encrypt" -ForegroundColor White
        Write-Host "  5. Point DNS to VPS IP`n" -ForegroundColor White
        
        Write-Host "Would you like to continue with quick tunnel for now? (Y/N)" -ForegroundColor Cyan
        $continue = Read-Host
        
        if ($continue -eq "Y" -or $continue -eq "y") {
            Write-Host "`nStarting quick tunnel...`n" -ForegroundColor Yellow
            .\cloudflared.exe tunnel --url http://localhost:8555
        }
    }
    
    default {
        Write-Host "`nInvalid choice. Exiting.`n" -ForegroundColor Red
        exit 1
    }
}
