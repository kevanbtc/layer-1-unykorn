# 🚀 Unykorn Production Deployment Guide

## ✅ COMPLETED: Polygon Mainnet Deployment (Phase 1)

**All 16 contracts successfully deployed to Polygon mainnet (chainId 137)**

### Deployed Addresses (Polygon)

```
Network: Polygon Mainnet
ChainId: 137
Deployer: 0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB
Block: 78095980
Timestamp: 2025-10-24T09:06:23.539Z
```

#### Core Tokens
- **UNYToken**: `0x7184F6345Dc6B224544201c3d930673e0F508466`
- **ComplianceRegistry**: `0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E`
- **VaultProofNFT**: `0x05B1d61e640246f9F6ECa2ca0C85682bB19F1557` ✅ Owned by LaunchVault
- **LaunchVault**: `0xcDBfE94f4db03853Cc6ddEd4367c218dc8f76b3B`

#### Licensing & Royalties
- **LicenseNFT**: `0x992348BD29c76dBA8aAAF316dcAbbF9f91C81b42`
- **RoyaltySplitter**: `0xEec6A64d44F135d2B4e799CFd35DD8a03c4184B7`
- **FeeRouter**: `0xDE3a9484c549256d6c1256F30C7Fd523F5Fd6023`

#### Oracles
- **PriceOracle**: `0xDc3218061Cf6d49B947e78b83571B806f1101216`
- **ComplianceOracle**: `0x60Be59aDd5C4c179eED542113fDBcC66b6Ef3c70`
- **WeatherOracle**: `0xd0178F66A63c71f164507A7968829bDf7BB070c4`

#### Advanced Tokens
- **ERC1155Carbon**: `0x2b67b5112f002541A1935cA66666Fc28CE3F4fBb`
- **ERC1400TaxEquity**: `0x77A9Ab8987097E44569A0333B8DB1284F5bE4758`
- **ERC3643Adapter (T-REX)**: `0x7778833f321d5f0204f32dddD8153FCa7Fb0A8cF`

#### Retirement System
- **BufferPool**: `0x2A2163f29DDA9450e764cB090e5AaE1a6084C806`
- **RetirementAttestation**: `0x7bc6131B51e33F50A714367C62E9df525B34c85a`

#### Marketplaces
- **RECMarketplace**: `0xa98DE35dF35522054463148d58951e95e83C1E6c`

---

## 🎯 NEXT PHASE: Unykorn L1 Deployment (ChainID 7777)

### Why Deploy to Your L1?

**You built Unykorn L1 for sovereignty.** Here's what you get:

✅ **FREE GAS** (you control UNYETH issuance)  
✅ **Your validators** (can't be censored)  
✅ **Instant upgrades** (no external governance)  
✅ **Your jurisdiction** (Dubai/Wyoming/etc.)  
✅ **Native tokenization** (UNY as gas token)  

**Polygon = liquidity backstop. Your L1 = canonical registry.**

---

## 📋 Step-by-Step: Deploy to Unykorn L1

### 1. Start Your L1 Nodes

```powershell
cd "c:\Users\Kevan\layer 1 build"
.\scripts\unykorn.ps1 start
```

**Verify nodes are running:**
```powershell
npx hardhat console --network unykorn
```
```js
(await ethers.provider.getNetwork()).chainId  // Should return 7777n
```

### 2. Fund Your Deployer on L1

**Pre-mine in genesis.json OR send from validator:**

```json
// genesis.json
{
  "alloc": {
    "0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB": {
      "balance": "0x152d02c7e14af6800000"  // 100,000 UNYETH
    }
  }
}
```

**Check balance:**
```powershell
npx hardhat console --network unykorn
```
```js
const [deployer] = await ethers.getSigners();
ethers.formatEther(await ethers.provider.getBalance(deployer.address))
```

### 3. Update hardhat.config.js

```js
// hardhat.config.js
networks: {
  unykorn: {
    url: process.env.UNYKORN_RPC || "http://localhost:8545",
    chainId: 7777,
    accounts: [process.env.DEPLOYER_KEY],
    gasPrice: 0,  // FREE GAS on your L1!
  },
  polygon: {
    url: process.env.POLYGON_RPC,
    chainId: 137,
    accounts: [process.env.DEPLOYER_KEY],
  }
}
```

### 4. Deploy All 16 Contracts to L1

```powershell
npx hardhat run scripts/deploy-energy-system.js --network unykorn
```

**Expected output:**
```
🚀 DEPLOYING UNYKORN GLOBAL ENERGY & CARBON SYSTEM
Network: unykorn (ChainID 7777)
Gas Price: 0 (FREE!)
Balance: 100000.0 UNYETH

✅ 16 contracts deployed
💾 Saved to: deployments/unykorn-7777.json
```

### 5. Transfer VaultProofNFT Ownership

```powershell
npx hardhat run scripts/transfer-nft-ownership.js --network unykorn
```

---

## 🔐 Production Security: Create Gnosis Safes

**Create 4 multisig Safes on your L1 + Polygon:**

### Safe Configuration

| Safe | Purpose | Signers | Threshold |
|------|---------|---------|-----------|
| **ADMIN_SAFE** | Governance, DEFAULT_ADMIN_ROLE | 5 hardware wallets | 3-of-5 |
| **TREASURY_SAFE** | Fees, royalties, withdrawals | 3 hardware wallets | 2-of-3 |
| **COMPLIANCE_SAFE** | Freezes, allowlists, pauses | 3 hardware wallets | 2-of-3 |
| **OPS_SAFE** | Markets, oracles, LaunchVault | 3 hardware wallets | 2-of-3 |
| **GUARDIAN_EOA** | Emergency pause only | 1 hardware wallet | 1-of-1 |

### Create Safes

1. Go to https://safe.global/
2. Connect to Polygon (137) or Unykorn L1 (7777)
3. Create each Safe with hardware wallet owners (Ledger/Trezor)
4. Copy Safe addresses to `.env`:

```env
# .env (add these)
ADMIN_SAFE=0x...
TREASURY_SAFE=0x...
COMPLIANCE_SAFE=0x...
OPS_SAFE=0x...
GUARDIAN_EOA=0x...  # Your hardware wallet address
```

### Wire All Ownerships

```powershell
npx hardhat run scripts/wire-ownerships-and-roles.js --network polygon
npx hardhat run scripts/wire-ownerships-and-roles.js --network unykorn
```

**This transfers:**
- ComplianceRegistry → COMPLIANCE_SAFE
- LaunchVault → OPS_SAFE
- RoyaltySplitter/FeeRouter → TREASURY_SAFE
- Oracles → OPS_SAFE / COMPLIANCE_SAFE
- All admin roles → ADMIN_SAFE
- Emergency pauses → COMPLIANCE_SAFE + GUARDIAN_EOA

---

## 🌉 Bridge Setup: Connect L1 ↔ Polygon

### Architecture

```
Unykorn L1 (7777) [CANONICAL]
     ↓ LayerZero Bridge
Polygon (137) [LIQUIDITY]
```

### Deploy Bridge Contracts

**On Unykorn L1:**
```solidity
CarbonVault (locks ERC1155Carbon)
```

**On Polygon:**
```solidity
UNYCarbonOFT (wrapped carbon, LayerZero OFT)
```

### Bridge Flow

1. **Lock on L1**: User calls `CarbonVault.lockAndBridge(tokenId, amount)`
2. **Mint on Polygon**: LayerZero mints `wUNY-Carbon` 1:1
3. **Trade on Polygon**: User sells on Toucan/KlimaDAO
4. **Burn & Unlock**: User burns on Polygon → unlocks on L1

---

## 💰 Insurance: Nexus Mutual Coverage

### Policy Configuration

```
Coverage Amount: $10,000,000
Premium: 2.5% annually ($250,000 in ETH)
Triggers:
  - L1 validator downtime >7 days
  - Bridge exploit resulting in asset loss
  - Smart contract bug causing token drain
Payout: USDC to affected users on Ethereum
```

### Purchase Coverage

1. Go to https://nexusmutual.io/
2. Connect wallet on Ethereum mainnet
3. Select "Protocol Cover"
4. Custom contract: Paste your L1 validator address
5. Set cover amount: $10M
6. Pay premium: $250K in ETH
7. Receive cover NFT

---

## ✅ Verification Checklist

### Polygon Mainnet

Run all verification commands:

```bash
# Core
npx hardhat verify --network polygon 0x7184F6345Dc6B224544201c3d930673e0F508466
npx hardhat verify --network polygon 0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E
npx hardhat verify --network polygon 0x05B1d61e640246f9F6ECa2ca0C85682bB19F1557
npx hardhat verify --network polygon 0xcDBfE94f4db03853Cc6ddEd4367c218dc8f76b3B 0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E 0x05B1d61e640246f9F6ECa2ca0C85682bB19F1557 10000000000000000000

# Licensing
npx hardhat verify --network polygon 0xEec6A64d44F135d2B4e799CFd35DD8a03c4184B7
npx hardhat verify --network polygon 0xDE3a9484c549256d6c1256F30C7Fd523F5Fd6023 0xEec6A64d44F135d2B4e799CFd35DD8a03c4184B7
npx hardhat verify --network polygon 0x992348BD29c76dBA8aAAF316dcAbbF9f91C81b42

# Oracles
npx hardhat verify --network polygon 0xDc3218061Cf6d49B947e78b83571B806f1101216
npx hardhat verify --network polygon 0x60Be59aDd5C4c179eED542113fDBcC66b6Ef3c70
npx hardhat verify --network polygon 0xd0178F66A63c71f164507A7968829bDf7BB070c4

# Advanced Tokens
npx hardhat verify --network polygon 0x2b67b5112f002541A1935cA66666Fc28CE3F4fBb
npx hardhat verify --network polygon 0x77A9Ab8987097E44569A0333B8DB1284F5bE4758 "UNY Tax Equity" "UNYTE"
npx hardhat verify --network polygon 0x7778833f321d5f0204f32dddD8153FCa7Fb0A8cF "UNY Securities" "UNYSEC" 0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E 0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E

# Retirement
npx hardhat verify --network polygon 0x2A2163f29DDA9450e764cB090e5AaE1a6084C806
npx hardhat verify --network polygon 0x7bc6131B51e33F50A714367C62E9df525B34c85a

# Markets
npx hardhat verify --network polygon 0xa98DE35dF35522054463148d58951e95e83C1E6c 0xDE3a9484c549256d6c1256F30C7Fd523F5Fd6023
```

---

## 🧪 End-to-End Smoke Test

```bash
npx hardhat console --network polygon
```

```js
// 1. Mint carbon credit
const carbon = await ethers.getContractAt("ERC1155Carbon", "0x2b67b5112f002541A1935cA66666Fc28CE3F4fBb");
const tokenId = await carbon.nextTokenId();
await (await carbon.createCreditType(
  ethers.encodeBytes32String("VCS"),
  "QmTest...",
  "VCS-001",
  "Test Project",
  2025,
  "US-CA",
  1000
)).wait();
console.log("✅ Carbon credit created");

// 2. List on marketplace
const market = await ethers.getContractAt("RECMarketplace", "0xa98DE35dF35522054463148d58951e95e83C1E6c");
await (await carbon.setApprovalForAll(market.target, true)).wait();
await (await market.createSellOrder(carbon.target, tokenId, 100, ethers.parseEther("30"))).wait();
console.log("✅ Listed 100 RECs at $30 each");

// 3. Retire credit
const retire = await ethers.getContractAt("RetirementAttestation", "0x7bc6131B51e33F50A714367C62E9df525B34c85a");
await (await carbon.setApprovalForAll(retire.target, true)).wait();
await (await retire.recordRetirement(
  deployer.address,
  ethers.encodeBytes32String("CARBON"),
  tokenId,
  10,
  "Test Company Inc.",
  ethers.encodeBytes32String("QmCert...")
)).wait();
console.log("✅ Retired 10 carbon credits");
```

---

## 📊 Cost Summary

| Action | Unykorn L1 | Polygon | Ethereum |
|--------|-----------|---------|----------|
| Deploy 16 contracts | **FREE** | $0.70 | $1,250 |
| Mint 10K carbon credits | **FREE** | $5 | $50 |
| Bridge to Polygon | **FREE** | $0.10/tx | N/A |
| Insurance (annual) | $0 | $0 | **$250K** |
| Stablecoin settlement | N/A | Native USDC | Native USDC |

**Total Annual Cost:** **$250K insurance only** (everything else is free on your L1)

---

## 🎉 Production Checklist

- [x] Deploy 16 contracts to Polygon
- [x] Transfer VaultProofNFT ownership to LaunchVault
- [ ] Deploy 16 contracts to Unykorn L1
- [ ] Create 4 Gnosis Safes (Admin, Treasury, Compliance, Ops)
- [ ] Wire all ownerships and roles to Safes
- [ ] Deploy bridge contracts (CarbonVault + UNYCarbonOFT)
- [ ] Purchase Nexus Mutual insurance ($10M coverage)
- [ ] Verify all contracts on Polygonscan
- [ ] Run end-to-end smoke tests
- [ ] Revoke deployer admin roles
- [ ] Launch publicly

---

## 📞 Support

Need help? Review the architecture docs:
- `docs/SR_LEVEL_ARCHITECTURE.md` (600+ lines)
- `docs/POLYGON_DEPLOYMENT.md`
- `docs/UNY_ID_SYSTEM.md`

**Your Unykorn L1 is the vault. Established chains are the insurance.** 🚀
