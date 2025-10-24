#!/usr/bin/env pwsh
# Quick smoke test runner

Write-Host "🎯 UNYKORN L1 SMOKE TEST SUITE`n" -ForegroundColor Cyan

# 1. Check Besu is running
Write-Host "1️⃣  Checking Besu node..." -ForegroundColor Yellow
$chainId = (Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
    -ContentType "application/json" `
    -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' `
    -ErrorAction SilentlyContinue).Content | ConvertFrom-Json | Select-Object -ExpandProperty result

if ($chainId) {
    $chainIdDec = [convert]::ToInt64($chainId, 16)
    Write-Host "   ✅ Besu responding: ChainID $chainId ($chainIdDec)`n" -ForegroundColor Green
} else {
    Write-Host "   ❌ Besu not responding. Start it with:" -ForegroundColor Red
    Write-Host "      docker compose -f .\docker\docker-compose.besu.yml up -d`n"
    exit 1
}

# 2. Check blocks are mining
Write-Host "2️⃣  Checking block production..." -ForegroundColor Yellow
$block1 = (Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
    -ContentType "application/json" `
    -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}').Content | ConvertFrom-Json | Select-Object -ExpandProperty result
Start-Sleep -Seconds 3
$block2 = (Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
    -ContentType "application/json" `
    -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}').Content | ConvertFrom-Json | Select-Object -ExpandProperty result

$block1Dec = [convert]::ToInt64($block1, 16)
$block2Dec = [convert]::ToInt64($block2, 16)

if ($block2Dec -gt $block1Dec) {
    Write-Host "   ✅ Blocks mining: $block1Dec → $block2Dec`n" -ForegroundColor Green
} else {
    Write-Host "   ❌ Blocks stuck at $block1Dec. Restart Besu.`n" -ForegroundColor Red
    exit 1
}

# 3. Check deployment file
Write-Host "3️⃣  Checking deployment file..." -ForegroundColor Yellow
if (Test-Path "deployments\localhost.json") {
    $deployment = Get-Content "deployments\localhost.json" | ConvertFrom-Json
    $contractCount = ($deployment.contracts | Get-Member -MemberType NoteProperty).Count
    Write-Host "   ✅ Found deployment with $contractCount contracts`n" -ForegroundColor Green
} else {
    Write-Host "   ❌ No deployment found. Deploy contracts first:" -ForegroundColor Red
    Write-Host "      npx hardhat run scripts/deploy-energy-system.js --network localhost`n"
    exit 1
}

# 4. Run mint test
Write-Host "4️⃣  Running mint test...`n" -ForegroundColor Yellow
npx hardhat run scripts\test-mint.js --network localhost

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✨ ALL TESTS PASSED! Your L1 is ready.`n" -ForegroundColor Green
} else {
    Write-Host "`n❌ Mint test failed. Check errors above.`n" -ForegroundColor Red
    exit 1
}
