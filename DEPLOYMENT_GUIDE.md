# 🚀 POLYGON MAINNET DEPLOYMENT - BATTLE PLAN

**Status**: Production-Ready  
**Target**: Polygon Mainnet (Chain ID: 137)  
**Timeline**: 25 minutes (deploy → verify → configure)

---

## ⚡ QUICK START (3 commands)

```bash
npm run preflight          # Validates everything (2 mins)
npm run deploy:polygon     # Deploys 4 contracts (5 mins)
npm run verify:polygon     # Verifies on Polygonscan (10 mins)
npm run snapshot:polygon   # Captures state (1 min)
```

---

## 📋 PHASE 0: PRE-FLIGHT (2 minutes)

### 1. Configure `.env`

```bash
# Required
POLYGON_RPC=https://polygon-rpc.com
DEPLOYER_PK=0xYOUR_64_CHAR_PRIVATE_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_API_KEY

# Optional (defaults provided)
TREASURY_ADDRESS=           # Defaults to deployer
INITIAL_SUPPLY=             # Defaults to 100M tokens
MINT_PRICE=                 # Defaults to 0.01 MATIC
```

**Get Polygonscan API Key**: https://polygonscan.com/myapikey

### 2. Fund Deployer

- **Minimum**: 0.5 MATIC
- **Recommended**: 1.0 MATIC (for retries + verify gas)
- Send to your deployer address (derived from DEPLOYER_PK)

### 3. Run Pre-Flight Check

```bash
npm run preflight
```

**Expected Output**:
```
✅ POLYGON_RPC configured
✅ DEPLOYER_PK configured
✅ Connected to Polygon (chainId: 137, block: XXXXX)
✅ Deployer balance: 1.23 MATIC
✅ All 4 core contracts found
✅ Solidity version: 0.8.24
✅ Optimizer runs: 2000
🎉 ALL CHECKS PASSED - READY FOR DEPLOYMENT!
```

---

## 🚢 PHASE 1: DEPLOY (5 minutes)

```bash
npm run deploy:polygon
```

**What it does**:
1. Deploys **UNYToken** (ERC-20 with Permit) - 100M supply
2. Deploys **VaultProofNFT** (ERC-721) - Soulbound NFT
3. Deploys **ComplianceRegistry** - Transfer gate logic
4. Deploys **LaunchVault** - Mint + payment processor
5. Transfers NFT ownership → LaunchVault (so it can mint)
6. Saves deployment record to `deployments/polygon-YYYYMMDD.json`

**Expected Output**:
```
🚀 POLYGON MAINNET DEPLOYMENT - UNYKORN VAULTPROOF SYSTEM

Deploying from account: 0xYourAddress
Account balance: 1.00 MATIC

✅ UNY Token deployed at:      0x1111...
✅ VaultProofNFT deployed at:   0x2222...
✅ ComplianceRegistry deployed: 0x3333...
✅ LaunchVault deployed at:     0x4444...
✅ Ownership transferred

📋 CANONICAL ADDRESSES (save these!):
Network: Polygon (137)
UNY (ERC-20):           0x1111...
VaultProofNFT (ERC-721): 0x2222...
ComplianceRegistry:     0x3333...
LaunchVault:            0x4444...
```

**⚠️ CRITICAL**: Save all 4 addresses immediately!

---

## 🔍 PHASE 2: VERIFY (10 minutes)

```bash
npm run verify:polygon
```

**What it does**:
- Submits source code + constructor args to Polygonscan
- Retries automatically if rate-limited
- Marks contracts with green ✓ checkmark on scanner

**Expected Output**:
```
🔍 VERIFYING CONTRACTS ON POLYGONSCAN

1️⃣  Verifying UNY Token...
   ✅ UNY Token verified
2️⃣  Verifying VaultProofNFT...
   ✅ VaultProofNFT verified
3️⃣  Verifying ComplianceRegistry...
   ✅ ComplianceRegistry verified
4️⃣  Verifying LaunchVault...
   ✅ LaunchVault verified

View on Polygonscan:
  UNY:        https://polygonscan.com/address/0x1111...#code
  NFT:        https://polygonscan.com/address/0x2222...#code
  Registry:   https://polygonscan.com/address/0x3333...#code
  Vault:      https://polygonscan.com/address/0x4444...#code
```

**Troubleshooting**:
- **"Already Verified"**: Great! Skip to next step.
- **Rate limited**: Wait 30 seconds, re-run.
- **Bytecode mismatch**: Check `hardhat.config.js` has `0.8.24` + `runs: 2000`.

---

## 📸 PHASE 3: SNAPSHOT (1 minute)

```bash
npm run snapshot:polygon
```

**What it does**:
- Captures on-chain state at current block
- Records total supply, ownership, NFT count
- Saves forensic trail to `snapshots/polygon-XXXXXXXX.json`

**Expected Output**:
```
📸 CAPTURING ON-CHAIN STATE SNAPSHOT

Network: polygon
Chain ID: 137
Block Number: 52847291

📊 UNY TOKEN (ERC-20)
  Name: Unykorn
  Symbol: UNY
  Total Supply: 100000000.0
  Owner: 0xYourAddress
  Paused: false

🖼️ VAULTPROOF NFT (ERC-721)
  Name: VaultProof
  Symbol: VPROOF
  Owner: 0x4444... (LaunchVault)
  Total Supply: 0

Snapshot saved: snapshots/polygon-52847291.json
```

---

## ✅ PHASE 4: POST-DEPLOYMENT CHECKLIST

### Immediate (5 minutes)

- [ ] **Polygonscan**: All 4 contracts show green ✓ verification
- [ ] **Constructor Args**: Properly decoded on scanner "Contract" tab
- [ ] **Git Tag**: `git tag -a v1.0.0-mainnet -m "Polygon launch" && git push --tags`
- [ ] **Backup**: Copy `deployments/*.json` to secure location (1Password/etc.)

### Within 1 Hour

- [ ] **Update README.md** with canonical addresses (see template below)
- [ ] **Pin NFT Metadata** to IPFS (Pinata/web3.storage)
- [ ] **Test Mint**: Call `LaunchVault.mint()` via Polygonscan "Write Contract" tab
- [ ] **Verify NFT Metadata**: Check OpenSea testnet shows image/attributes

### Within 24 Hours

- [ ] **Seed Liquidity**: Create QuickSwap UNY/USDC pool
- [ ] **OpenSea Collection**: Submit for listing (requires 1+ mint)
- [ ] **Frontend**: Deploy Next.js app with contract addresses
- [ ] **Monitor**: Set up alerts (Tenderly/Defender)

---

## 📝 README.md Template (Copy/Paste)

```markdown
## 🌐 Canonical Addresses — Polygon (137)

| Contract            | Address                                    | Polygonscan                                    |
|---------------------|--------------------------------------------|------------------------------------------------|
| **UNY (ERC-20)**    | `0x1111...` | [View](https://polygonscan.com/address/0x1111...) |
| **VaultProofNFT**   | `0x2222...` | [View](https://polygonscan.com/address/0x2222...) |
| **ComplianceRegistry** | `0x3333...` | [View](https://polygonscan.com/address/0x3333...) |
| **LaunchVault**     | `0x4444...` | [View](https://polygonscan.com/address/0x4444...) |

**Deployment**: `deployments/polygon-20250124.json`  
**Snapshot**: `snapshots/polygon-52847291.json`  
**Block**: 52,847,291 (Jan 24, 2025)

### 🔗 Ecosystem Links

- **QuickSwap**: [UNY/USDC](https://quickswap.exchange/#/swap?inputCurrency=0x1111...&outputCurrency=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
- **OpenSea**: [VaultProof Collection](https://opensea.io/assets/matic/0x2222...)
- **DexScreener**: [UNY Chart](https://dexscreener.com/polygon/0x...)
```

---

## 🔧 COMMON SNAGS & FIXES

### 1. "Insufficient funds for gas"
**Fix**: Fund deployer with 0.5+ MATIC, re-run `npm run deploy:polygon`

### 2. "Bytecode doesn't match"
**Fix**: Ensure `hardhat.config.js` has:
```js
solidity: {
  version: "0.8.24",
  settings: { optimizer: { enabled: true, runs: 2000 } }
}
```

### 3. "Rate limited" during verification
**Fix**: Wait 30 seconds, re-run `npm run verify:polygon`

### 4. OpenSea not showing NFT
**Fix**: 
1. Mint at least 1 NFT via `LaunchVault.mint()`
2. Go to `opensea.io/assets/matic/0x2222.../1`
3. Click "Refresh metadata" button

### 5. "Contract already deployed at this address"
**Fix**: This is from a previous run. Check `deployments/*.json` for addresses.

---

## 🎯 NEXT: PIVOT TO UNY-ID STACK

Once basic tokens are live, deploy the full **Energy & RWA Passport** system:

```bash
npm run deploy:unyid:polygon
```

This deploys the 7-contract identity/compliance/MRV stack:
- **IdentityNFT** (DID + ERC-6551)
- **AttestationRegistry** (9 credential schemas)
- **ComplianceRegistry** (dynamic rules)
- **DeviceOracle** (MRV data ingress)
- **ERC1155REC** (energy certificates)
- **ERC1400Adapter** (regulated securities)
- **RetirementLocker** (anti-double-count)

**Full Guide**: See `UNY_ID_QUICKSTART.md`

---

## 📞 SUPPORT

**Deployment Issues**: Check `TROUBLESHOOTING.md`  
**Architecture Questions**: See `docs/ARCHITECTURE.md`  
**Contract Docs**: See `docs/UNY_ID_SYSTEM.md`

---

**Status**: Ready to launch 🚀  
**Last Updated**: October 24, 2025  
**Deployed By**: You (tonight!)
