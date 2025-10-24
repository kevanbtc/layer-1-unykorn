# Unykorn L1 - PowerShell Management Script
# Usage: .\scripts\unykorn.ps1 <command>

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"

function Show-Help {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "  Unykorn L1 - Layer 1 Blockchain Management" -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\scripts\unykorn.ps1 <command>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Besu Commands:" -ForegroundColor Green
    Write-Host "  besu-init       Initialize Besu network"
    Write-Host "  besu-up         Start Besu network"
    Write-Host "  besu-down       Stop Besu network"
    Write-Host "  besu-logs       View Besu logs"
    Write-Host ""
    Write-Host "Polygon-Edge Commands:" -ForegroundColor Green
    Write-Host "  edge-init       Initialize Polygon-Edge network"
    Write-Host "  edge-up         Start Polygon-Edge network"
    Write-Host "  edge-down       Stop Polygon-Edge network"
    Write-Host "  edge-logs       View Polygon-Edge logs"
    Write-Host ""
    Write-Host "Testing:" -ForegroundColor Green
    Write-Host "  test-rpc        Test RPC endpoint"
    Write-Host "  ps              Show running containers"
    Write-Host ""
}

# Command router
switch ($Command.ToLower()) {
    "help" {
        Show-Help
    }
    "besu-init" {
        Write-Host "Initializing Besu network..." -ForegroundColor Yellow
        docker-compose -f docker/docker-compose.besu.yml run --rm besu-init
    }
    "besu-up" {
        Write-Host "Starting Besu network..." -ForegroundColor Yellow
        docker-compose -f docker/docker-compose.besu.yml up -d
        Write-Host "Besu running at http://localhost:8545" -ForegroundColor Green
    }
    "besu-down" {
        docker-compose -f docker/docker-compose.besu.yml down
    }
    "besu-logs" {
        docker-compose -f docker/docker-compose.besu.yml logs -f
    }
    "edge-init" {
        Write-Host "Initializing Polygon-Edge network..." -ForegroundColor Yellow
        docker-compose -f docker/docker-compose.edge.yml run --rm edge-init
    }
    "edge-up" {
        Write-Host "Starting Polygon-Edge network..." -ForegroundColor Yellow
        docker-compose -f docker/docker-compose.edge.yml up -d
        Write-Host "Edge running at http://localhost:8545" -ForegroundColor Green
    }
    "edge-down" {
        docker-compose -f docker/docker-compose.edge.yml down
    }
    "edge-logs" {
        docker-compose -f docker/docker-compose.edge.yml logs -f
    }
    "test-rpc" {
        Write-Host "Testing RPC..." -ForegroundColor Yellow
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8545" -Method Post -ContentType "application/json" -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' -TimeoutSec 5
            if ($response.result -eq "0x1e61") {
                Write-Host "RPC is responding! Chain ID: 7777" -ForegroundColor Green
            }
        } catch {
            Write-Host "RPC test failed. Is the network running?" -ForegroundColor Red
        }
    }
    "ps" {
        docker ps --filter "name=besu" --filter "name=edge"
    }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Show-Help
    }
}
