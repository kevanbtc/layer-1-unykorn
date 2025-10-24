# ⚡ Quick Command Reference

Copy-paste these commands for instant execution.

---

## 🔍 Status Checks

### Check Besu is Mining
```powershell
for ($i=0; $i -lt 5; $i++) {
  $block = (Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
    -ContentType "application/json" `
    -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}').Content | ConvertFrom-Json
  Write-Host "Block: $($block.result) ($([convert]::ToInt64($block.result, 16)))"
  Start-Sleep -Seconds 2
}
```

### Check ChainID
```powershell
(Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
  -ContentType "application/json" `
  -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}').Content
```

---

## 🚀 Deploy Commands

### Deploy to Localhost (ChainID 1337)
```powershell
npx hardhat run scripts/deploy-energy-system.js --network localhost
```

### Deploy to Polygon Mainnet
```powershell
npx hardhat run scripts/deploy-energy-system.js --network polygon
```

### Deploy to Unykorn L1 (ChainID 7777)
```powershell
npx hardhat run scripts/deploy-energy-system.js --network unykorn
```

---

## 🧪 Testing Commands

### Smoke Test (Mint NFT)
```powershell
npx hardhat run scripts/test-mint.js --network localhost
```

### Wire Ownerships to Safes
```powershell
npx hardhat run scripts/wire-ownerships-and-roles.js --network localhost
```

### Transfer NFT Ownership
```powershell
npx hardhat run scripts/transfer-nft-ownership.js --network localhost
```

---

## ✅ Verification Commands

### Verify All Polygon Contracts
```powershell
npm run verify:all:polygon
```

### Verify Single Contract
```powershell
npx hardhat verify --network polygon 0x7184F6345Dc6B224544201c3d930673e0F508466 "0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB" "1000000000000000000000000000"
```

---

## 🐳 Docker Commands

### Start Besu Dev Mode (ChainID 1337)
```powershell
docker compose -f .\docker\docker-compose.besu.yml up -d
```

### Stop and Clean Besu
```powershell
docker compose -f .\docker\docker-compose.besu.yml down -v
```

### View Besu Logs
```powershell
docker logs unykorn-besu-validator-1 --tail 50 --follow
```

### Restart Besu
```powershell
docker compose -f .\docker\docker-compose.besu.yml restart besu-validator-1
```

---

## 📊 Hardhat Console (Interactive)

### Start Console on Localhost
```powershell
npx hardhat console --network localhost
```

### Inside Console - Get Contract
```javascript
const UNY = await ethers.getContractAt("UNYToken", "0x5FbDB2315678afecb367f032d93F642f64180aa3")
await UNY.name()
await UNY.symbol()
await UNY.totalSupply()
```

### Inside Console - Check Balance
```javascript
const [signer] = await ethers.getSigners()
console.log("Address:", signer.address)
console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(signer.address)))
```

### Exit Console
Press `Ctrl+D` or type `.exit`

---

## 🔐 MetaMask Import

### Import Deployer Account
1. MetaMask → Import Account → Private Key
2. Paste: `0x7b2b32f0d6f78140c8803bec4469978d9737d9bb458e95cef8c85bb912520b55`
3. Address: `0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB`

### Add Localhost Network (ChainID 1337)
```javascript
await window.ethereum.request({
  method: 'wallet_addEthereumChain',
  params: [{
    chainId: '0x539',
    chainName: 'Unykorn L1 (Dev)',
    rpcUrls: ['http://127.0.0.1:8545'],
    nativeCurrency: { name: 'UnyETH', symbol: 'UNYETH', decimals: 18 }
  }]
})
```

### Add Unykorn L1 Network (ChainID 7777)
```javascript
await window.ethereum.request({
  method: 'wallet_addEthereumChain',
  params: [{
    chainId: '0x1e61',
    chainName: 'Unykorn L1',
    rpcUrls: ['http://127.0.0.1:8545'],
    nativeCurrency: { name: 'UnyETH', symbol: 'UNYETH', decimals: 18 }
  }]
})
```

---

## 📁 File Locations

| File | Purpose |
|------|---------|
| `deployments/localhost.json` | Dev chain contracts (ChainID 1337) |
| `deployments/polygon.json` | Polygon mainnet contracts (ChainID 137) |
| `hardhat.config.js` | Network configurations |
| `docker/docker-compose.besu.yml` | Besu validator config |
| `configs/genesis.json` | Custom genesis for ChainID 7777 |
| `.env` | Private keys and API keys |

---

## 🆘 Quick Fixes

### "Chain ID mismatch" Error
Check which chain is running:
```powershell
(Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
  -ContentType "application/json" `
  -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}').Content
```

Update `hardhat.config.js` to match the returned chainId.

### "No deployment file found" Error
```powershell
# Check what's in deployments folder
Get-ChildItem deployments\*.json
```

### Blocks Stuck at 0
```powershell
# Full reset
docker compose -f .\docker\docker-compose.besu.yml down -v
docker compose -f .\docker\docker-compose.besu.yml up -d
Start-Sleep 10
# Check blocks again
```

---

## 🎯 Common Workflows

### Fresh Local Deploy
```powershell
# 1. Ensure Besu is running
docker compose -f .\docker\docker-compose.besu.yml up -d

# 2. Wait for blocks
Start-Sleep 10

# 3. Deploy contracts
npx hardhat run scripts/deploy-energy-system.js --network localhost

# 4. Test mint
npx hardhat run scripts/test-mint.js --network localhost
```

### Verify Polygon Deployment
```powershell
# Check deployment file exists
cat deployments\polygon.json

# Verify all contracts
npm run verify:all:polygon
```

### Switch to Production ChainID 7777
See `L1_DEPLOYMENT_GUIDE.md` → "Production Environment" section

---

**Pro Tip:** Keep this file open in a second VS Code tab for instant copy-paste! 🚀
