# Unykorn L1 Production Deployment Script
# Generates secure validator keys, JWT secret, and production genesis
# 
# Usage: .\scripts\production-setup.ps1 -NumValidators 4

param(
    [int]$NumValidators = 4,
    [string]$OutputDir = "production",
    [switch]$GenerateKeys = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Unykorn L1 Mainnet - Production Setup" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "ERROR: Docker is not running. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Create production directory structure
Write-Host "[1/6] Creating production directories..." -ForegroundColor Yellow
$dirs = @(
    "$OutputDir",
    "$OutputDir/keys",
    "$OutputDir/backups"
)

foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    }
}

# Generate JWT secret for engine API
Write-Host "`n[2/6] Generating JWT secret..." -ForegroundColor Yellow
if (!(Test-Path "$OutputDir/jwt-secret.hex")) {
    $jwtBytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($jwtBytes)
    $jwtHex = ($jwtBytes | ForEach-Object { $_.ToString("x2") }) -join ""
    $jwtHex | Out-File -FilePath "$OutputDir/jwt-secret.hex" -Encoding ascii -NoNewline
    Write-Host "  JWT secret created: $OutputDir/jwt-secret.hex" -ForegroundColor Green
} else {
    Write-Host "  JWT secret already exists (skipping)" -ForegroundColor Gray
}

# Generate validator keys (if requested)
if ($GenerateKeys) {
    Write-Host "`n[3/6] Generating validator keys..." -ForegroundColor Yellow
    Write-Host "  WARNING: Keys will be generated ONLINE. For maximum security," -ForegroundColor Red
    Write-Host "  generate keys on an air-gapped machine and import them." -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "  Continue with online key generation? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "  Skipped. Import keys manually into $OutputDir/validator-*/key" -ForegroundColor Yellow
        Write-Host ""
    } else {
        for ($i = 0; $i -lt $NumValidators; $i++) {
            $validatorDir = "$OutputDir/validator-$i"
            if (!(Test-Path $validatorDir)) {
                New-Item -ItemType Directory -Path $validatorDir -Force | Out-Null
            }
            
            # Generate key using Besu container
            Write-Host "  Generating validator $i keys..." -ForegroundColor Cyan
            docker run --rm -v "${PWD}/${validatorDir}:/data" `
                hyperledger/besu:24.1 `
                --data-path=/data `
                public-key export --to=/data/key.pub | Out-Null
            
            if (Test-Path "$validatorDir/key.pub") {
                $pubKey = Get-Content "$validatorDir/key.pub"
                Write-Host "    Validator $i public key: $pubKey" -ForegroundColor Green
            }
        }
        Write-Host "  All validator keys generated!" -ForegroundColor Green
    }
} else {
    Write-Host "`n[3/6] Validator key generation skipped" -ForegroundColor Gray
    Write-Host "  Use -GenerateKeys flag to generate, or import manually" -ForegroundColor Yellow
}

# Create encrypted backup
Write-Host "`n[4/6] Creating encrypted key backup..." -ForegroundColor Yellow
if (Test-Path "$OutputDir/validator-0/key") {
    $backupFile = "$OutputDir/backups/validator-keys-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    Compress-Archive -Path "$OutputDir/validator-*" -DestinationPath $backupFile
    Write-Host "  Backup created: $backupFile" -ForegroundColor Green
    Write-Host "  IMPORTANT: Store this backup in a secure, encrypted location!" -ForegroundColor Red
} else {
    Write-Host "  No keys to backup (generate or import keys first)" -ForegroundColor Yellow
}

# Extract validator addresses for genesis
Write-Host "`n[5/6] Extracting validator addresses..." -ForegroundColor Yellow
$validatorAddresses = @()
for ($i = 0; $i -lt $NumValidators; $i++) {
    $validatorDir = "$OutputDir/validator-$i"
    if (Test-Path "$validatorDir/key.pub") {
        # Use Besu to get address from public key
        $address = docker run --rm -v "${PWD}/${validatorDir}:/data" `
            hyperledger/besu:24.1 `
            public-key export-address --node-public-key-file=/data/key.pub
        
        $validatorAddresses += $address.Trim()
        Write-Host "  Validator $i address: $address" -ForegroundColor Green
    }
}

if ($validatorAddresses.Count -eq 0) {
    Write-Host "  No validator addresses extracted" -ForegroundColor Yellow
    Write-Host "  Generate keys first, then re-run this script" -ForegroundColor Yellow
}

# Generate production genesis
Write-Host "`n[6/6] Genesis configuration..." -ForegroundColor Yellow
if (Test-Path "production/genesis-template.json") {
    Write-Host "  Template found: production/genesis-template.json" -ForegroundColor Green
    Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Edit genesis-template.json" -ForegroundColor White
    Write-Host "     - Replace treasury/foundation addresses" -ForegroundColor White
    Write-Host "     - Add validator addresses to extraData" -ForegroundColor White
    Write-Host "  2. Use Besu operator tools to generate final genesis" -ForegroundColor White
    Write-Host "  3. Save as: $OutputDir/genesis.json" -ForegroundColor White
} else {
    Write-Host "  ERROR: genesis-template.json not found" -ForegroundColor Red
}

# Summary
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  Production Setup Summary" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created:" -ForegroundColor Yellow
Write-Host "  JWT Secret:      $OutputDir/jwt-secret.hex"
Write-Host "  Validators:      $NumValidators"
if ($validatorAddresses.Count -gt 0) {
    Write-Host "  Key Backup:      $backupFile"
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Backup keys to encrypted, offline storage"
Write-Host "  2. Configure genesis with real addresses"
Write-Host "  3. Review production/docker-compose.production.yml"
Write-Host "  4. Set firewall rules (see docs/PRODUCTION_SECURITY.md)"
Write-Host "  5. Deploy with: docker-compose -f production/docker-compose.production.yml up -d"
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
