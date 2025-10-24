# 🏗️ Unykorn L1 Deployment Guide

Complete guide for deploying to your local Unykorn L1 blockchain environments.

---

## 🎯 Two Environments Available

| Environment | ChainID | Purpose | Status |
|-------------|---------|---------|--------|
| **localhost** | 1337 | Fast dev/testing | ✅ Ready |
| **unykorn** | 7777 | Sovereign production L1 | 🔜 Config needed |

---

## 🚀 Quick Start: Development Environment (ChainID 1337)

### Current Status
✅ **WORKING NOW** - Besu dev mode mining blocks every 2 seconds

### Prerequisites
```powershell
# Ensure Besu is running
docker compose -f .\docker\docker-compose.besu.yml up -d besu-validator-1

# Verify blocks are mining
for ($i=0; $i -lt 3; $i++) {
    $block = (Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
        -ContentType "application/json" `
        -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}').Content | ConvertFrom-Json
    Write-Host "Block: $($block.result) ($([convert]::ToInt64($block.result, 16)))"
    Start-Sleep -Seconds 2
}
```

### Deploy All Contracts
```powershell
npx hardhat run scripts/deploy-energy-system.js --network localhost
```

**Expected Output:**
```
🚀 DEPLOYING UNYKORN GLOBAL ENERGY & CARBON SYSTEM
Network: localhost
ChainId: 1337
Deployer: 0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB
Balance: 2650.0 ETH

📦 PHASE 1: Core Tokens
1/16: Deploying UNYToken...
✅ UNYToken deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3

[... 16 contracts total ...]

✨ DEPLOYMENT COMPLETE
Time: 45.23s
💾 Saved to: deployments\localhost.json
```

### Run Smoke Tests
```powershell
# Test basic contract interactions
npx hardhat run scripts/test-mint.js --network localhost

# Wire ownerships to Safes (optional)
npx hardhat run scripts/wire-ownerships-and-roles.js --network localhost
```

### Interactive Console
```powershell
npx hardhat console --network localhost
```

```javascript
// Inside console
const UNY = await ethers.getContractAt("UNYToken", "0x5FbDB2315678afecb367f032d93F642f64180aa3")
await UNY.name()  // "Unykorn Token"
await UNY.symbol()  // "UNY"
```

---

## 🏛️ Production Environment: Sovereign Unykorn L1 (ChainID 7777)

### Why Use This?
- True sovereign blockchain with your chosen chainId
- Multi-validator consensus (QBFT)
- Persistent state across restarts
- Production-grade configuration

### Prerequisites

1. **Update genesis.json** (`configs/genesis.json`):

```json
{
  "config": {
    "chainId": 7777,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "qbft": {
      "blockperiodseconds": 2,
      "epochlength": 30000,
      "requesttimeoutseconds": 10
    }
  },
  "nonce": "0x0",
  "timestamp": "0x0",
  "extraData": "0xf83ea00000000000000000000000000000000000000000000000000000000000000000d594fe3b557e8fb62b89f4916b721be55ceb828dbd73c080c0",
  "gasLimit": "0x1fffffffffffff",
  "difficulty": "0x1",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
    "9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    }
  }
}
```

2. **Create docker-compose.qbft.yml**:

```yaml
version: '3.8'

services:
  besu-validator-1:
    image: hyperledger/besu:latest
    container_name: unykorn-besu-validator-1
    restart: unless-stopped
    ports:
      - "8545:8545"
      - "8546:8546"
      - "30303:30303"
    environment:
      - BESU_LOGGING=INFO
    volumes:
      - besu-qbft-data:/opt/besu/data
      - ./configs/genesis.json:/opt/besu/genesis.json
    command:
      - --genesis-file=/opt/besu/genesis.json
      - --data-path=/opt/besu/data
      - --rpc-http-enabled=true
      - --rpc-http-host=0.0.0.0
      - --rpc-http-port=8545
      - --rpc-http-api=ETH,NET,WEB3,ADMIN,DEBUG,TXPOOL,QBFT
      - --rpc-http-cors-origins=*
      - --rpc-ws-enabled=true
      - --rpc-ws-host=0.0.0.0
      - --rpc-ws-port=8546
      - --rpc-ws-api=ETH,NET,WEB3
      - --host-allowlist=*
      - --min-gas-price=0
      - --miner-enabled=true
      - --miner-coinbase=0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB
    networks:
      - unykorn-network

volumes:
  besu-qbft-data:
    driver: local

networks:
  unykorn-network:
    driver: bridge
```

3. **Launch Sovereign L1**:

```powershell
# Stop dev mode if running
docker compose -f .\docker\docker-compose.besu.yml down

# Start QBFT mode
docker compose -f .\docker\docker-compose.qbft.yml up -d

# Verify chainId
(Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
    -ContentType "application/json" `
    -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}').Content
# Should return: {"jsonrpc":"2.0","id":1,"result":"0x1e61"}

# Verify block production
for ($i=0; $i -lt 5; $i++) {
    $block = (Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
        -ContentType "application/json" `
        -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}').Content | ConvertFrom-Json
    Write-Host "Block: $($block.result)"
    Start-Sleep -Seconds 3
}
```

4. **Deploy to ChainID 7777**:

```powershell
npx hardhat run scripts/deploy-energy-system.js --network unykorn
```

---

## 🔌 MetaMask Configuration

### Add Localhost (ChainID 1337)

```javascript
// In browser console or MetaMask
await window.ethereum.request({
  method: 'wallet_addEthereumChain',
  params: [{
    chainId: '0x539',
    chainName: 'Unykorn L1 (Dev)',
    rpcUrls: ['http://127.0.0.1:8545'],
    nativeCurrency: {
      name: 'UnyETH',
      symbol: 'UNYETH',
      decimals: 18
    },
    blockExplorerUrls: null
  }]
});
```

### Add Sovereign Unykorn L1 (ChainID 7777)

```javascript
await window.ethereum.request({
  method: 'wallet_addEthereumChain',
  params: [{
    chainId: '0x1e61',
    chainName: 'Unykorn L1',
    rpcUrls: ['http://127.0.0.1:8545'],
    nativeCurrency: {
      name: 'UnyETH',
      symbol: 'UNYETH',
      decimals: 18
    },
    blockExplorerUrls: ['http://localhost:4000']
  }]
});
```

### Import Deployer Account

1. Open MetaMask → Import Account → Private Key
2. Paste: `0x7b2b32f0d6f78140c8803bec4469978d9737d9bb458e95cef8c85bb912520b55`
3. Account will show: `0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB`
4. Balance: 2650 UNYETH (dev mode) or 1B UNYETH (sovereign mode)

**⚠️ SECURITY NOTE:** This is a test key. Never use it with real funds!

---

## 📋 Contract Addresses (ChainID 1337)

After deployment to localhost, contracts are at:

| Contract | Address |
|----------|---------|
| UNYToken | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| ComplianceRegistry | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` |
| VaultProofNFT | `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` |
| LaunchVault | `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` |
| LicenseNFT | `0x0165878A594ca255338adfa4d48449f69242Eb8F` |
| RoyaltySplitter | `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9` |
| FeeRouter | `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707` |
| PriceOracle | `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853` |
| ComplianceOracle | `0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6` |
| WeatherOracle | `0x8A791620dd6260079BF849Dc5567aDC3F2FdC318` |
| ERC1155Carbon | `0x610178dA211FEF7D417bC0e6FeD39F05609AD788` |
| ERC1400TaxEquity | `0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e` |
| ERC3643Adapter | `0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0` |
| BufferPool | `0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82` |
| RetirementAttestation | `0x9A676e781A523b5d0C0e43731313A708CB607508` |
| RECMarketplace | `0x0B306BF915C4d645ff596e518fAf3F9669b97016` |

*Addresses are deterministic and will be the same on fresh deployments to localhost.*

---

## 🔍 Troubleshooting

### Blocks Not Mining

```powershell
# Check Besu logs
docker logs unykorn-besu-validator-1 --tail 50

# Common fix: restart with clean state
docker compose -f .\docker\docker-compose.besu.yml down -v
docker compose -f .\docker\docker-compose.besu.yml up -d
```

### Chain ID Mismatch

```
Error: HH101: Hardhat was set to use chain id 7777, but connected to a chain with id 1337
```

**Solution**: Check which Besu config is running, then update `hardhat.config.js` to match:

```javascript
localhost: {
  url: "http://127.0.0.1:8545",
  chainId: 1337,  // Match what eth_chainId returns
  accounts: process.env.DEPLOYER_PK ? [process.env.DEPLOYER_PK] : []
}
```

### Deployment Hangs

```powershell
# Check RPC connectivity
Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
    -ContentType "application/json" `
    -Body '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}'
```

### Contract Already Deployed

The deployment script has **resume capability**. It will:
- Load `deployments/<network>.json`
- Skip already-deployed contracts
- Continue from where it left off

To force fresh deployment:
```powershell
# Backup existing deployment
Copy-Item deployments\localhost.json deployments\localhost.backup.json

# Delete deployment file
Remove-Item deployments\localhost.json

# Re-deploy from scratch
npx hardhat run scripts/deploy-energy-system.js --network localhost
```

---

## 🎯 Next Steps

### ✅ Development Phase (Use ChainID 1337)
1. Run smoke tests: `npx hardhat run scripts/test-mint.js --network localhost`
2. Test contract interactions in console
3. Build and test Safe App UI integration
4. Develop oracle integrations

### 🏗️ Production Phase (Upgrade to ChainID 7777)
1. Configure multi-validator QBFT consensus
2. Set up static-nodes.json for validator peering
3. Deploy to sovereign L1
4. Set up Blockscout explorer at http://explorer.unykorn.org
5. Configure public RPC endpoints

### 🌍 Public Mainnet (Already Live!)
- **Polygon contracts**: Verified and live at block 78,095,980
- **Verification**: `npm run verify:all:polygon`
- **Safe App**: Deploy to https://console.unykorn.org

---

## 📚 Related Docs

- [Hardhat Networks Config](hardhat.config.js)
- [Deployment Script](scripts/deploy-energy-system.js)
- [Polygon Deployment Guide](POLYGON_READY.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT.md)
- [Safe Integration](SAFE_QUICKSTART.md)

---

## 🆘 Support

**ChainID Confusion?**
- Localhost (1337) = Fast dev/testing
- Unykorn (7777) = Your sovereign production L1
- Polygon (137) = Public mainnet (already live)

**Deployment Issues?**
Check `deployments/<network>.json` for existing addresses and use resume feature.

**Need Production QBFT Config?**
Request the full multi-validator setup guide with static-nodes and validator keys.
