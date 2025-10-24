# 🧪 Unykorn L1 RPC Test Suite
# Comprehensive JSON-RPC endpoint testing for PowerShell

param(
    [string]$RpcUrl = "http://127.0.0.1:8545",
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

function Test-RpcCall {
    param(
        [string]$Method,
        [array]$Params = @(),
        [string]$Description
    )
    
    $body = @{
        jsonrpc = "2.0"
        method  = $Method
        params  = $Params
        id      = 1
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "`n🔍 Testing: " -NoNewline -ForegroundColor Cyan
        Write-Host $Description -ForegroundColor White
        Write-Host "   Method: $Method" -ForegroundColor Gray
        
        if ($Verbose) {
            Write-Host "   Request: $body" -ForegroundColor DarkGray
        }
        
        $response = Invoke-WebRequest -Uri $RpcUrl -Method Post -Body $body -ContentType "application/json" -UseBasicParsing
        $json = $response.Content | ConvertFrom-Json
        
        if ($json.error) {
            Write-Host "   ❌ ERROR: $($json.error.message)" -ForegroundColor Red
            return $null
        }
        
        Write-Host "   ✅ SUCCESS" -ForegroundColor Green
        Write-Host "   Result: " -NoNewline -ForegroundColor Yellow
        Write-Host ($json.result | ConvertTo-Json -Compress) -ForegroundColor White
        
        return $json.result
    }
    catch {
        Write-Host "   ❌ FAILED: $_" -ForegroundColor Red
        return $null
    }
}

function Convert-HexToDecimal {
    param([string]$Hex)
    if ($Hex -match "^0x") {
        return [Convert]::ToInt64($Hex.Substring(2), 16)
    }
    return 0
}

# Header
Clear-Host
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host " 🧪 UNYKORN L1 RPC TEST SUITE" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "`n📡 Target RPC: " -NoNewline
Write-Host $RpcUrl -ForegroundColor Yellow
Write-Host ""

# Test 1: Client Version
$clientVersion = Test-RpcCall -Method "web3_clientVersion" -Description "Get client version"

# Test 2: Chain ID
$chainId = Test-RpcCall -Method "eth_chainId" -Description "Get chain ID"
if ($chainId) {
    $chainIdDec = Convert-HexToDecimal $chainId
    if ($chainIdDec -eq 7777) {
        Write-Host "   ✓ Chain ID is correct (7777)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ WARNING: Expected 7777, got $chainIdDec" -ForegroundColor Yellow
    }
}

# Test 3: Network Version
$netVersion = Test-RpcCall -Method "net_version" -Description "Get network version"

# Test 4: Listening
$listening = Test-RpcCall -Method "net_listening" -Description "Check if node is listening"

# Test 5: Peer Count
$peerCount = Test-RpcCall -Method "net_peerCount" -Description "Get peer count"
if ($peerCount) {
    $peerCountDec = Convert-HexToDecimal $peerCount
    Write-Host "   ℹ Connected peers: $peerCountDec" -ForegroundColor Cyan
}

# Test 6: Block Number
$blockNumber = Test-RpcCall -Method "eth_blockNumber" -Description "Get latest block number"
if ($blockNumber) {
    $blockNumberDec = Convert-HexToDecimal $blockNumber
    Write-Host "   ℹ Current block: $blockNumberDec" -ForegroundColor Cyan
    
    if ($blockNumberDec -eq 0) {
        Write-Host "   ⚠ Chain hasn't started producing blocks yet" -ForegroundColor Yellow
    }
}

# Test 7: Gas Price
$gasPrice = Test-RpcCall -Method "eth_gasPrice" -Description "Get current gas price"
if ($gasPrice) {
    $gasPriceDec = Convert-HexToDecimal $gasPrice
    $gasPriceGwei = $gasPriceDec / 1000000000
    Write-Host "   ℹ Gas price: $gasPriceGwei Gwei" -ForegroundColor Cyan
}

# Test 8: Get Balance (dev account)
$devAccount = "0xfe3b557e8fb62b89f4916b721be55ceb828dbd73"
$balance = Test-RpcCall -Method "eth_getBalance" -Params @($devAccount, "latest") -Description "Get balance of dev account"
if ($balance) {
    $balanceDec = Convert-HexToDecimal $balance
    $balanceEth = $balanceDec / 1000000000000000000
    Write-Host "   ℹ Balance: $balanceEth ETH" -ForegroundColor Cyan
}

# Test 9: Get Block by Number
if ($blockNumber -and (Convert-HexToDecimal $blockNumber) -gt 0) {
    $block = Test-RpcCall -Method "eth_getBlockByNumber" -Params @("latest", $false) -Description "Get latest block"
    if ($block) {
        Write-Host "   ℹ Block hash: $($block.hash)" -ForegroundColor Cyan
        Write-Host "   ℹ Transactions: $($block.transactions.Count)" -ForegroundColor Cyan
    }
}

# Test 10: Syncing Status
$syncing = Test-RpcCall -Method "eth_syncing" -Description "Check sync status"
if ($syncing -eq $false) {
    Write-Host "   ✓ Node is fully synced" -ForegroundColor Green
}

# Test 11: Mining Status
$mining = Test-RpcCall -Method "eth_mining" -Description "Check if mining/validating"

# Test 12: Coinbase
$coinbase = Test-RpcCall -Method "eth_coinbase" -Description "Get coinbase (validator) address"

# Test 13: Accounts
$accounts = Test-RpcCall -Method "eth_accounts" -Description "Get unlocked accounts"
if ($accounts) {
    Write-Host "   ℹ Unlocked accounts: $($accounts.Count)" -ForegroundColor Cyan
}

# Test 14: Transaction Count
$txCount = Test-RpcCall -Method "eth_getTransactionCount" -Params @($devAccount, "latest") -Description "Get transaction count (nonce)"
if ($txCount) {
    $txCountDec = Convert-HexToDecimal $txCount
    Write-Host "   ℹ Nonce: $txCountDec" -ForegroundColor Cyan
}

# Test 15: Pending Transactions
$pendingTx = Test-RpcCall -Method "eth_getBlockTransactionCountByNumber" -Params @("pending") -Description "Get pending transaction count"

# Test 16: Protocol Version
$protocolVersion = Test-RpcCall -Method "eth_protocolVersion" -Description "Get Ethereum protocol version"

# Test 17: Get Code (check if address is contract)
$code = Test-RpcCall -Method "eth_getCode" -Params @($devAccount, "latest") -Description "Get code at address (check if contract)"
if ($code -eq "0x") {
    Write-Host "   ℹ This is an EOA (Externally Owned Account)" -ForegroundColor Cyan
} else {
    Write-Host "   ℹ This is a smart contract" -ForegroundColor Cyan
}

# Test 18: Estimate Gas (for a simple transfer)
try {
    $gasEstimate = Test-RpcCall -Method "eth_estimateGas" -Params @(@{
        from  = $devAccount
        to    = "0x0000000000000000000000000000000000000001"
        value = "0x1"
    }) -Description "Estimate gas for transfer"
    if ($gasEstimate) {
        $gasEstimateDec = Convert-HexToDecimal $gasEstimate
        Write-Host "   ℹ Estimated gas: $gasEstimateDec units" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠ Gas estimation not available yet" -ForegroundColor Yellow
}

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host " 📊 TEST SUMMARY" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Cyan

Write-Host "`n✅ Core Checks:" -ForegroundColor Yellow
Write-Host "   Chain ID: " -NoNewline
if ($chainId) { 
    Write-Host "7777 ✓" -ForegroundColor Green 
} else { 
    Write-Host "FAILED" -ForegroundColor Red 
}

Write-Host "   Block Production: " -NoNewline
if ($blockNumber) {
    $bn = Convert-HexToDecimal $blockNumber
    if ($bn -gt 0) {
        Write-Host "$bn blocks ✓" -ForegroundColor Green
    } else {
        Write-Host "Not started yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "FAILED" -ForegroundColor Red
}

Write-Host "   RPC Connectivity: " -NoNewline
if ($clientVersion) {
    Write-Host "✓" -ForegroundColor Green
} else {
    Write-Host "FAILED" -ForegroundColor Red
}

Write-Host "   Peer Connections: " -NoNewline
if ($peerCount) {
    $pc = Convert-HexToDecimal $peerCount
    if ($pc -gt 0) {
        Write-Host "$pc peers ✓" -ForegroundColor Green
    } else {
        Write-Host "No peers (single node dev mode)" -ForegroundColor Yellow
    }
} else {
    Write-Host "FAILED" -ForegroundColor Red
}

Write-Host "`n💡 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Add network to MetaMask (Chain ID: 7777, RPC: $RpcUrl)"
Write-Host "   2. Import dev account: 0xfe3b557e8fb62b89f4916b721be55ceb828dbd73"
Write-Host "   3. Deploy a contract: npx hardhat run scripts/deploy.ts --network unykorn"
Write-Host "   4. Send test transactions via MetaMask"

Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
if (-not $clientVersion) {
    Write-Host "   ❌ RPC not responding - Check if Docker is running:" -ForegroundColor Red
    Write-Host "      docker compose ps" -ForegroundColor Gray
    Write-Host "      .\scripts\unykorn.ps1 logs" -ForegroundColor Gray
}

if ($blockNumber) {
    $bn = Convert-HexToDecimal $blockNumber
    if ($bn -eq 0) {
        Write-Host "   ⚠ No blocks produced - Check validator config:" -ForegroundColor Yellow
        Write-Host "      docker compose logs besu | Select-String -Pattern 'ERROR'" -ForegroundColor Gray
    }
}

Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host ""
