# 🚀 Polygon Mainnet Deployment Guide

Complete step-by-step guide for deploying the Unykorn VaultProof system to Polygon mainnet.

---

## 📋 Pre-Deployment Checklist

### Required Tools
- [ ] Node.js 18+ installed
- [ ] Hardhat configured
- [ ] MetaMask with deployer account
- [ ] Polygonscan API key (for verification)

### Required Funds
- [ ] **0.1+ MATIC** in deployer account (for gas fees)
- [ ] Test deployment on Mumbai first (recommended)

### Required Information
- [ ] **Treasury address** (where initial UNY tokens go)
- [ ] **Deployer private key** (keep secure!)
- [ ] **Polygonscan API key** (from polygonscan.com)

---

## 🛠️ Setup Instructions

### Step 1: Install Dependencies

```bash
npm install
npm install --save-dev @nomicfoundation/hardhat-verify dotenv
```

### Step 2: Configure Environment

Create `.env` file (copy from `.env.example`):

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
POLYGON_RPC=https://polygon-rpc.com
DEPLOYER_PK=0xYOUR_PRIVATE_KEY_HERE
POLYGONSCAN_API_KEY=YOUR_API_KEY_HERE
TREASURY_ADDRESS=0xYOUR_TREASURY_ADDRESS
```

**⚠️ SECURITY**: Never commit `.env` to git!

### Step 3: Verify Configuration

```bash
# Check deployer balance
npx hardhat run scripts/check-balance.js --network polygon

# Test RPC connection
.\scripts\test-rpc-suite.ps1 -RpcUrl "https://polygon-rpc.com"
```

Expected: Chain ID `0x89` (137), gas price returned, block number advancing.

---

## 🚀 Deployment Process

### Step 4: Compile Contracts

```bash
npx hardhat compile
```

Expected output: Contracts compiled successfully.

### Step 5: Deploy to Polygon Mainnet

```bash
npx hardhat run scripts/deploy-polygon.js --network polygon
```

**Expected output:**
```
🚀 POLYGON MAINNET DEPLOYMENT
✅ UNY Token deployed at: 0x...
✅ VaultProofNFT deployed at: 0x...
✅ ComplianceRegistry deployed at: 0x...
✅ LaunchVault deployed at: 0x...
💾 Deployment record saved to: polygon-20251024.json
```

**⏱️ Duration**: ~2-3 minutes

### Step 6: Save Deployment Addresses

Copy the four addresses from console output:

```
UNY (ERC-20):           0x...
VaultProofNFT (ERC-721): 0x...
ComplianceRegistry:      0x...
LaunchVault:             0x...
```

**Save these immediately!** They're also in `deployments/polygon-YYYYMMDD.json`

---

## 🔍 Contract Verification

### Step 7: Verify on Polygonscan

Option A: **Automated (recommended)**

```bash
npx hardhat run scripts/verify-all.js --network polygon
```

Option B: **Manual verification**

```bash
# UNY Token
npx hardhat verify --network polygon 0xUNY_ADDRESS "0xTREASURY" "100000000000000000000000000"

# VaultProofNFT
npx hardhat verify --network polygon 0xNFT_ADDRESS

# ComplianceRegistry
npx hardhat verify --network polygon 0xREGISTRY_ADDRESS

# LaunchVault
npx hardhat verify --network polygon 0xLAUNCH_ADDRESS "0xREGISTRY" "0xNFT" "10000000000000000"
```

**⏱️ Duration**: ~5 minutes

### Step 8: Verify on Polygonscan UI

Visit each contract:
- `https://polygonscan.com/address/0xYOUR_CONTRACT_ADDRESS#code`
- Should show green checkmark ✅ "Contract Source Code Verified"

---

## 🎨 NFT Metadata Setup

### Step 9: Prepare NFT Metadata

Create `metadata/1.json`:

```json
{
  "name": "VaultProof #1",
  "description": "Proof of participation in Unykorn Launch Vault",
  "image": "ipfs://YOUR_IMAGE_CID/image.png",
  "attributes": [
    {"trait_type": "Tier", "value": "Genesis"},
    {"trait_type": "Mint Date", "value": "2025-10-24"}
  ]
}
```

### Step 10: Pin to IPFS

**Option A: Pinata**
1. Upload image → Get CID
2. Update `metadata/1.json` with image CID
3. Upload `1.json` → Get metadata CID

**Option B: web3.storage**
```bash
npm install -g @web3-storage/w3cli
w3 login
w3 up metadata/
```

**Result**: `ipfs://YOUR_CID/1.json`

---

## 🧪 Testing Deployment

### Step 11: Test Mint via Console

```bash
npx hardhat console --network polygon
```

```javascript
// Get contracts
const LaunchVault = await ethers.getContractAt("LaunchVault", "0xLAUNCH_ADDRESS");
const VaultProofNFT = await ethers.getContractAt("VaultProofNFT", "0xNFT_ADDRESS");

// Mint NFT
const mintTx = await LaunchVault.mint("ipfs://YOUR_CID/1.json", {
  value: ethers.parseEther("0.01")
});
await mintTx.wait();

// Verify mint
const totalSupply = await VaultProofNFT.totalSupply();
console.log("Total minted:", totalSupply.toString());

// Check owner
const owner = await VaultProofNFT.ownerOf(1);
console.log("Token #1 owner:", owner);
```

### Step 12: View on OpenSea

1. Wait 2-3 minutes for OpenSea indexing
2. Visit: `https://opensea.io/assets/matic/0xNFT_ADDRESS/1`
3. Verify image and metadata appear

**Troubleshooting**:
- If image doesn't load: Check IPFS CID is correct
- If metadata wrong: Update JSON and re-pin
- If not showing: Click "Refresh metadata" on OpenSea

---

## 💧 Liquidity Setup

### Step 13: Mint UNY for Liquidity

```bash
npx hardhat console --network polygon
```

```javascript
const UNY = await ethers.getContractAt("UNYToken", "0xUNY_ADDRESS");

// Mint 2.5M UNY to LP wallet
await UNY.mint("0xYOUR_LP_WALLET", ethers.parseUnits("2500000", 18));
```

### Step 14: Create QuickSwap Pool

1. Go to: https://quickswap.exchange/#/add
2. Select tokens: **UNY** (paste address) + **USDC**
3. Fee tier: **0.3%** (recommended for new tokens)
4. Set initial price (e.g., 1 UNY = 0.10 USDC)
5. Add liquidity (e.g., 100k UNY + 10k USDC)
6. Confirm transaction

**Result**: UNY/USDC pair created, LP tokens received.

---

## 📸 State Snapshot

### Step 15: Capture On-Chain State

```bash
npx hardhat run scripts/snapshot.js --network polygon
```

**Output**: `snapshots/snapshot-polygon-20251024-blockXXXXXX.json`

Contains:
- Total supply (UNY & NFT)
- Owner addresses
- Paused status
- Mint price
- LaunchVault balance
- Block number & timestamp

**Purpose**: Audit trail for external verification.

---

## 📝 Documentation Updates

### Step 16: Update README.md

Add this section to your README:

```markdown
## 📍 Canonical Addresses (Polygon Mainnet)

| Contract | Address |
|----------|---------|
| **UNY Token (ERC-20)** | `0xYOUR_UNY_ADDRESS` |
| **VaultProofNFT (ERC-721)** | `0xYOUR_NFT_ADDRESS` |
| **ComplianceRegistry** | `0xYOUR_REGISTRY_ADDRESS` |
| **LaunchVault** | `0xYOUR_LAUNCH_ADDRESS` |

### Links
- **Polygonscan**: [UNY Token](https://polygonscan.com/address/0xYOUR_UNY_ADDRESS)
- **OpenSea**: [VaultProof Collection](https://opensea.io/collection/vaultproof)
- **QuickSwap**: [Trade UNY/USDC](https://quickswap.exchange/#/swap?inputCurrency=0xYOUR_UNY_ADDRESS&outputCurrency=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)

### Deployed
- **Network**: Polygon (137)
- **Block**: 50,123,456
- **Date**: October 24, 2025
- **Deployer**: `0xYOUR_DEPLOYER_ADDRESS`
```

---

## 🔒 Security & Ownership

### Step 17: Transfer Ownership (Optional)

**For LaunchVault** (if you want multisig control):
```javascript
const LaunchVault = await ethers.getContractAt("LaunchVault", "0xLAUNCH_ADDRESS");
await LaunchVault.transferOwnership("0xMULTISIG_ADDRESS");
```

**For UNY Token** (choose one):
- **Renounce** (fully decentralized, irreversible):
  ```javascript
  await UNY.renounceOwnership();
  ```
- **Transfer to multisig** (recommended):
  ```javascript
  await UNY.transferOwnership("0xMULTISIG_ADDRESS");
  ```

**⚠️ WARNING**: Renouncing means NO ONE can mint more UNY or pause transfers. Only do this if intended!

---

## 🏷️ Release Tagging

### Step 18: Git Commit & Tag

```bash
# Add deployment files
git add deployments/ snapshots/ README.md

# Commit
git commit -m "Polygon mainnet launch: UNY/NFT/Registry/LaunchVault"

# Tag release
git tag -a v1.0.0 -m "Mainnet launch (Polygon) - October 24, 2025"

# Push
git push origin main
git push --tags
```

---

## 📊 Post-Deployment Monitoring

### Step 19: Set Up Monitoring

**Tenderly** (recommended):
1. Sign up at tenderly.co
2. Add contracts: UNY, NFT, Registry, LaunchVault
3. Enable alerts: Failed transactions, ownership changes

**DeBank/OKLink**:
- Add contract addresses to watch list
- Track liquidity, holders, volume

### Step 20: Announce Launch

**Twitter/X**:
```
🚀 Unykorn VaultProof is LIVE on Polygon!

📍 Contract: 0xYOUR_NFT_ADDRESS
🎨 OpenSea: [link]
💧 Trade UNY: [QuickSwap link]

Mint your VaultProof NFT for 0.01 MATIC
[Website link]
```

**Discord/Telegram**:
- Post canonical addresses
- Share mint instructions
- Provide liquidity pool link

---

## ✅ Deployment Complete Checklist

- [ ] All 4 contracts deployed successfully
- [ ] Contracts verified on Polygonscan (green checkmarks)
- [ ] NFT metadata pinned to IPFS
- [ ] Test mint completed successfully
- [ ] NFT visible on OpenSea
- [ ] QuickSwap liquidity pool created
- [ ] UNY/USDC pair trading live
- [ ] State snapshot captured
- [ ] README.md updated with addresses
- [ ] Git tagged with v1.0.0
- [ ] Monitoring set up (Tenderly/DeBank)
- [ ] Public announcement posted

**When all checked**: 🎉 **MAINNET LAUNCH SUCCESSFUL!**

---

## 🚨 Troubleshooting

### Gas Estimation Failed
**Cause**: Insufficient MATIC or contract error  
**Fix**: Check balance, verify constructor args

### Verification Failed
**Cause**: Constructor args mismatch  
**Fix**: Check `deployments/*.json` for exact args used

### OpenSea Not Showing NFT
**Cause**: Indexing delay or metadata issue  
**Fix**: Wait 5 minutes, click "Refresh metadata"

### Transaction Stuck
**Cause**: Low gas price  
**Fix**: Speed up transaction in MetaMask or use faster RPC

### "Ownable: caller is not the owner"
**Cause**: Trying to call owner-only function  
**Fix**: Use deployer account or check ownership was transferred

---

## 📚 Next Steps

After successful mainnet launch:

1. **ERC-6551 Integration**: Token-bound accounts per VaultProof NFT
2. **Compliance Hooks**: Default-deny mode + sanctions provider
3. **Revenue Split**: On-chain UNY buyback from mint fees
4. **Timelock**: Gnosis Safe + Defender Relays for admin ops
5. **Staking**: Lockup periods + yield distribution

---

## 🔗 Useful Links

- **Polygon Docs**: https://docs.polygon.technology
- **QuickSwap**: https://quickswap.exchange
- **OpenSea**: https://opensea.io
- **Polygonscan**: https://polygonscan.com
- **Tenderly**: https://tenderly.co

---

**Deploy with confidence. Audit with precision. Launch with momentum.** 🚀
