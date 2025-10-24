# 🏠 Unykorn L1 - The Mothership Launch Guide

## Overview

**Unykorn L1 (ChainId 7777)** is now your **default network** and canonical registry. All tokenization happens here first. **FREE GAS**. Your validators. Your rules.

**Multi-Chain Strategy:**
- **Unykorn L1 (7777)**: Canonical registry (zero gas, full control) ← **DEFAULT**
- **Polygon (137)**: Liquidity layer (DEX trading, USDC settlement)
- **Ethereum (1)**: Insurance layer (Nexus Mutual $10M coverage)

---

## 🚀 Quick Start (3 Commands)

### 1. Start Your L1 Nodes

```powershell
cd "c:\Users\Kevan\layer 1 build"
.\scripts\unykorn.ps1 start
```

This boots your Besu validators on chainId 7777.

### 2. Deploy All 16 Contracts (FREE GAS!)

```powershell
npm run deploy:energy:unykorn
```

Deploys the complete energy tokenization suite:
- ✅ 4 Core Tokens (UNY, ComplianceRegistry, VaultProofNFT, LaunchVault)
- ✅ 3 Licensing (LicenseNFT, RoyaltySplitter, FeeRouter)
- ✅ 3 Oracles (PriceOracle, ComplianceOracle, WeatherOracle)
- ✅ 3 Advanced Tokens (ERC1155Carbon, ERC1400TaxEquity, ERC3643Adapter)
- ✅ 2 Retirement (BufferPool, RetirementAttestation)
- ✅ 1 Marketplace (RECMarketplace)

**Cost:** $0.00 (FREE GAS on your L1!)

### 3. Transfer NFT Ownership

```powershell
npm run transfer:nft:unykorn
```

Transfers VaultProofNFT ownership to LaunchVault so contributions automatically mint NFTs.

---

## 🔐 Production Security Setup

### Step 1: Create 4 Gnosis Safes on Safe.global

Go to https://app.safe.global/ and create:

1. **ADMIN_SAFE** (3-of-5 signers)
   - **Purpose**: Governance, DEFAULT_ADMIN_ROLE
   - **Signers**: Founder 1, Founder 2, Founder 3, Legal Counsel, CTO

2. **TREASURY_SAFE** (2-of-3 signers)
   - **Purpose**: Fees, royalties, withdrawals
   - **Signers**: CFO, Treasurer, Founder

3. **COMPLIANCE_SAFE** (2-of-3 signers)
   - **Purpose**: Freezes, allowlists, pauses
   - **Signers**: Compliance Officer, Legal Counsel, External Auditor

4. **OPS_SAFE** (2-of-3 signers)
   - **Purpose**: Markets, oracles, LaunchVault operations
   - **Signers**: CTO, DevOps Lead, Product Manager

5. **GUARDIAN_EOA** (1-of-1 hardware wallet)
   - **Purpose**: Emergency pause ONLY
   - **Device**: Ledger/Trezor cold wallet

### Step 2: Add Safe Addresses to .env

```env
# === Gnosis Safes (Unykorn L1) ===
ADMIN_SAFE=0x...
TREASURY_SAFE=0x...
COMPLIANCE_SAFE=0x...
OPS_SAFE=0x...
GUARDIAN_EOA=0x...
```

### Step 3: Wire All Ownerships to Safes

```powershell
npm run wire:safes:unykorn
```

This transfers:
- **ComplianceRegistry** → COMPLIANCE_SAFE
- **LaunchVault** → OPS_SAFE
- **RoyaltySplitter + FeeRouter** → TREASURY_SAFE
- **Oracles** → OPS_SAFE + COMPLIANCE_SAFE
- **All admin roles** → ADMIN_SAFE
- **Emergency pauses** → COMPLIANCE_SAFE + GUARDIAN_EOA
- **Deployer** → ALL ROLES REVOKED ✅

---

## 💰 Genesis Configuration (Free Gas Forever)

### Option 1: Zero Gas Price (Recommended)

Edit your Besu node config:

```bash
# besu.conf or command-line flags
--min-gas-price=0
--rpc-http-enabled
--rpc-http-api=ETH,NET,WEB3,TXPOOL,ADMIN
--host-allowlist=*
```

With `--min-gas-price=0`, your L1 accepts **gasPrice: 0** transactions (already configured in `hardhat.config.js`).

### Option 2: Pre-Fund Deployer in Genesis

Create `configs/genesis-unykorn.json`:

```json
{
  "config": {
    "chainId": 7777,
    "berlinBlock": 0,
    "londonBlock": 0,
    "ibft2": {
      "blockperiodseconds": 2,
      "epochlength": 30000,
      "requesttimeoutseconds": 10,
      "validators": [
        "0xVALIDATOR_1",
        "0xVALIDATOR_2",
        "0xVALIDATOR_3",
        "0xVALIDATOR_4"
      ]
    }
  },
  "nonce": "0x0",
  "timestamp": "0x0",
  "gasLimit": "0x1c9c380",
  "difficulty": "0x1",
  "mixHash": "0x63746963616c20686578206d6978686173680000000000000000000000000000",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
    "0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB": {
      "balance": "0xd3c21bcecceda1000000"
    }
  },
  "number": "0x0",
  "gasUsed": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
}
```

**Pre-funded balance:** 1,000,000 UNYETH (0xd3c21bcecceda1000000 wei)

Replace `0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB` with your deployer address.

---

## 🧪 Smoke Test (Prove Full Control)

```powershell
npx hardhat console --network unykorn
```

```javascript
// Check network
const network = await ethers.provider.getNetwork();
console.log("ChainId:", network.chainId); // Should be 7777n

// Get deployed addresses
const deployment = require("./deployments/unykorn.json");

// Attach to contracts
const LaunchVault = await ethers.getContractAt("LaunchVault", deployment.contracts.launchVault);
const VaultProofNFT = await ethers.getContractAt("VaultProofNFT", deployment.contracts.vaultProofNFT);

// Contribute 10 UNYETH (should mint NFT)
const [signer] = await ethers.getSigners();
const tx = await LaunchVault.contribute({ value: ethers.parseEther("10") });
await tx.wait();

// Check NFT balance (should be 1)
const balance = await VaultProofNFT.balanceOf(signer.address);
console.log("VaultProofNFT Balance:", balance.toString()); // 1

// ✅ SUCCESS! LaunchVault minted your NFT on Unykorn L1
```

---

## 🌉 Optional: Bridge to Polygon (Later)

Once Unykorn L1 is stable, you can deploy LayerZero bridge contracts:

1. **CarbonVault.sol** on Unykorn L1 (locks real ERC1155Carbon tokens)
2. **UNYCarbonOFT.sol** on Polygon (mints wrapped wUNY-Carbon for trading)

**Flow:**
- Lock on L1 → LayerZero message → Mint on Polygon
- Trade on Polygon DEXs (Uniswap, Curve)
- Burn on Polygon → LayerZero message → Unlock on L1
- Retire on L1 (RetirementAttestation)

**Why?** Canonical assets stay on L1 (zero gas), liquidity layer on Polygon ($5/day gas), insurance on Ethereum ($250K/year Nexus Mutual).

---

## 📊 Cost Comparison

| Action | Unykorn L1 | Polygon | Ethereum |
|--------|-----------|---------|----------|
| **Deploy 16 contracts** | **FREE** | $0.70 | $1,250 |
| **Mint 10K carbon credits** | **FREE** | $5 | $50 |
| **Daily operations** | **$0** | **~$5** | ~$150 |
| **Annual insurance** | $0 | $0 | **$250K** |
| **Total annual** | **$0** | **~$1,800** | **~$305K** |

**Your L1 = $0 forever.** Polygon = cheap liquidity. Ethereum = expensive insurance.

---

## 🛡️ Mainnet Guard (Prevents Accidents)

The deployment script now **blocks Polygon mainnet** unless you explicitly confirm:

```powershell
# This will FAIL (safety guard)
npm run deploy:energy:polygon

# This will SUCCEED (explicit confirmation)
$env:CONFIRM_MAINNET="YES"; npm run deploy:energy:polygon
```

**Why?** Prevents accidental re-deployments to Polygon when you meant to deploy to L1.

---

## 📦 Package.json Scripts Reference

```json
{
  "scripts": {
    "deploy:energy:unykorn": "hardhat run scripts/deploy-energy-system.js --network unykorn",
    "deploy:energy:polygon": "hardhat run scripts/deploy-energy-system.js --network polygon",
    "transfer:nft:unykorn": "hardhat run scripts/transfer-nft-ownership.js --network unykorn",
    "transfer:nft:polygon": "hardhat run scripts/transfer-nft-ownership.js --network polygon",
    "wire:safes:unykorn": "hardhat run scripts/wire-ownerships-and-roles.js --network unykorn",
    "wire:safes:polygon": "hardhat run scripts/wire-ownerships-and-roles.js --network polygon"
  }
}
```

**Default network:** Unykorn L1 (7777)  
**Explicit override:** Use `--network polygon` for Polygon deployments

---

## ✅ Launch Checklist

### Immediate (Next 1 Hour)
- [ ] Start Unykorn L1 nodes: `.\scripts\unykorn.ps1 start`
- [ ] Deploy all 16 contracts: `npm run deploy:energy:unykorn`
- [ ] Transfer NFT ownership: `npm run transfer:nft:unykorn`
- [ ] Run smoke test (console commands above)

### Production Security (Next 2 Hours)
- [ ] Create 4 Gnosis Safes on Safe.global (ADMIN, TREASURY, COMPLIANCE, OPS)
- [ ] Create GUARDIAN_EOA (hardware wallet)
- [ ] Add Safe addresses to `.env`
- [ ] Wire all ownerships: `npm run wire:safes:unykorn`
- [ ] Test emergency pause (GUARDIAN_EOA)

### Bridge Layer (Week 1)
- [ ] Deploy CarbonVault to Unykorn L1
- [ ] Deploy UNYCarbonOFT to Polygon
- [ ] Configure LayerZero trusted remotes
- [ ] Test lock → mint → burn → unlock flow

### Insurance & Legal (Week 2)
- [ ] Purchase Nexus Mutual $10M coverage on Ethereum
- [ ] File Reg D Form D (if issuing tax equity tokens)
- [ ] Obtain IRC §48/45 tax opinion
- [ ] Set up Chainalysis compliance monitoring

### Audits (Weeks 3-4)
- [ ] Run Slither + Mythril (static analysis)
- [ ] Certora formal verification ($50K, 2 weeks)
- [ ] Trail of Bits manual audit ($100K, 4 weeks)
- [ ] Fix all findings

### Public Launch (Week 5)
- [ ] Revoke deployer admin roles (final step)
- [ ] Publish SR_LEVEL_ARCHITECTURE.md
- [ ] Onboard pilot solar/wind projects
- [ ] Issue first RECs and carbon credits
- [ ] 🎉 **GO LIVE**

---

## 🎯 Why Unykorn L1 is the Mothership

1. **FREE GAS** - Zero transaction costs forever
2. **Your validators** - Can't be censored or shut down
3. **Instant upgrades** - Your governance, your timeline
4. **Regulatory clarity** - Your jurisdiction, your rules
5. **Full control** - No dependencies on external chains

**Polygon = liquidity layer** (cheap DEX trading)  
**Ethereum = insurance layer** ($10M Nexus Mutual coverage)  
**Unykorn L1 = canonical source of truth** (FREE, sovereign, yours)

---

## 🔗 Next Steps

1. **Start L1:** `.\scripts\unykorn.ps1 start`
2. **Deploy:** `npm run deploy:energy:unykorn`
3. **Transfer NFT:** `npm run transfer:nft:unykorn`
4. **Create Safes:** https://app.safe.global/ (4 multisigs)
5. **Wire Ownerships:** `npm run wire:safes:unykorn`
6. **Smoke Test:** `npx hardhat console --network unykorn`

**Your L1 is ready. Let's make it canonical.** 🚀
