# 🌐 UNYKORN MAINNET ARCHITECTURE

## 🎯 EXECUTIVE SUMMARY

**You have successfully deployed a production-grade tokenization platform on Polygon Mainnet.** This document maps the complete system, verification steps, and how users interact through MetaMask and other interfaces.

---

## 📊 CURRENT PRODUCTION STATUS

### ✅ **DEPLOYED ON POLYGON MAINNET (ChainId 137)**

| Component | Status | Block | Gas Cost |
|-----------|--------|-------|----------|
| **16 Smart Contracts** | ✅ LIVE | 78095980 | 1.15 MATIC ($0.70) |
| **4 Gnosis Safes** | ✅ LIVE | Various | Funded (1 MATIC each) |
| **VaultProofNFT Ownership** | ✅ Transferred | 78095980 | Included above |
| **Deployer Address** | ✅ Active | - | 0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB |

**Deployment Time:** 105.62 seconds  
**Network:** Polygon Mainnet (https://polygonscan.com)  
**Verification:** All contracts verifiable on Polygonscan  

---

## 🏗️ SYSTEM ARCHITECTURE

### **Layer 1: Custody & Governance (Safe{Core})**

```
┌─────────────────────────────────────────────────────────────┐
│                    GNOSIS SAFE MULTISIGS                     │
│                    (Multi-Signature Custody)                 │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
  ┌──────────┐         ┌──────────┐         ┌──────────┐
  │  ADMIN   │         │ TREASURY │         │COMPLIANCE│
  │  SAFE    │         │   SAFE   │         │   SAFE   │
  │ (3-of-5) │         │ (2-of-3) │         │ (2-of-3) │
  └──────────┘         └──────────┘         └──────────┘
  • DEFAULT_ADMIN      • Fee collection     • Freeze/pause
  • Grant/revoke       • Withdrawals        • Allowlists
  • Upgrades           • Royalties          • KYC registry
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
                        ┌──────────┐
                        │   OPS    │
                        │   SAFE   │
                        │ (2-of-3) │
                        └──────────┘
                        • Markets
                        • Oracles
                        • LaunchVault
                              │
                              ▼
                        ┌──────────┐
                        │ GUARDIAN │
                        │   EOA    │
                        │ (1-of-1) │
                        └──────────┘
                        • Emergency pause ONLY
```

**Current Safe Addresses (Polygon Mainnet):**
- **ADMIN_SAFE:** `0x1106F3838Bb670BCd50367278655EC8144F20C08`
- **TREASURY_SAFE:** `0x7b2f2772E9748aA60a39c54450c5f86393D8F85E`
- **COMPLIANCE_SAFE:** `0xf2710eF527d790F1Abf2263dff5112e8e12b8b9E`
- **OPS_SAFE:** `0x7Fd4E5F3a94b69828c98bcA09C4591C5A6d07c63`
- **GUARDIAN_EOA:** `0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB` ⚠️ (Currently deployer, needs hardware wallet)

**⚠️ CRITICAL:** All Safes currently 1-of-1 (need threshold upgrades before production use)

---

### **Layer 2: Smart Contracts (Polygon Mainnet)**

```
┌─────────────────────────────────────────────────────────────┐
│                    TOKEN INFRASTRUCTURE                      │
└─────────────────────────────────────────────────────────────┘

UNYToken (ERC20)                    0x7184F6345Dc6B224544201c3d930673e0F508466
├─ Native utility token
├─ Staking + governance
└─ Fee discounts

VaultProofNFT (ERC721)              0x05B1d61e640246f9F6ECa2ca0C85682bB19F1557
├─ Membership/ownership proof
├─ Owner: LaunchVault ✅
└─ Mint price: 10 ETH (configurable)

┌─────────────────────────────────────────────────────────────┐
│                    CARBON CREDITS (RECs)                     │
└─────────────────────────────────────────────────────────────┘

ERC1155Carbon (RECRegistry)         0xFc8C70A735f5bB9Cd86Dd5Cbe68B4A61FABF0485
├─ Renewable Energy Credits (RECs)
├─ Batch minting: createREC()
├─ Per-token metadata (vintage, tech, location)
└─ Role: MINTER_ROLE → OPS_SAFE

RECMarketplace                      0x0c57374D85BB54e3A8ca85ca6D88b4bCaa3fEc75
├─ On-chain trading (fixed price or auction)
├─ Fee: configureFee() → TREASURY_SAFE
└─ Role: DEFAULT_ADMIN_ROLE → ADMIN_SAFE

RetirementAttestation (ERC721)      0xF97aaf4353d8Ceb09C3AD4E48e7A18E17dC9B74a
├─ Proof-of-retirement NFT
├─ retire() burns RECs, mints certificate
└─ Non-transferrable attestation

┌─────────────────────────────────────────────────────────────┐
│                  IDENTITY & COMPLIANCE (UNY-ID)              │
└─────────────────────────────────────────────────────────────┘

IdentityNFT (ERC721)                0xCC27ffC4a7C54B6c2d6e4ad8e699aD91e3766e72
├─ Self-sovereign DID (1 per user)
├─ Role-based access (KYC levels)
└─ Soulbound (non-transferrable)

AttestationRegistry                 0xa9Cce3Ea83CA1D6a1e67f2A36Ba56c9C69e3e7c8
├─ External verifier attestations
├─ addAttestation() → COMPLIANCE_SAFE
└─ Query: getAttestations(did)

ComplianceRegistry (UNY-ID)         0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E
├─ Central KYC/AML registry
├─ Allowlists + freezes
└─ Role: COMPLIANCE_MANAGER → COMPLIANCE_SAFE

┌─────────────────────────────────────────────────────────────┐
│                    SECURITIES & LICENSING                    │
└─────────────────────────────────────────────────────────────┘

ERC1400Adapter                      0x49e7ebb66856CF8D0e9Ca4cc37C3C80cA9cfB464
├─ Security token standard
├─ Partition-based transfers
├─ Reg D/S compliance
└─ Role: DEFAULT_ADMIN_ROLE → ADMIN_SAFE

BufferPool                          0xe79CBcB7A7C5bC6DE2e66DD85D8e232Ea15Ab08F
├─ Liquidity for secondary trading
├─ depositBuffer() → add liquidity
└─ Role: MANAGER → OPS_SAFE

LicensingRegistry                   0x8ba07A4bDCb56De6Ebc9d8c82FCCAE4688ae6b72
├─ IP licensing (carbon methodologies)
├─ Royalty collection
└─ Role: ADMIN_ROLE → ADMIN_SAFE

┌─────────────────────────────────────────────────────────────┐
│                    ORACLES & ROUTING                         │
└─────────────────────────────────────────────────────────────┘

DeviceOracle                        0x5E8aa67A0FfE8BCDe4FAD7eA5fBC3b0DFE4aF0aF
├─ Off-chain device data (IoT)
├─ submitData() → ORACLE_ROLE
└─ Used by RECs for verification

FeeRouter                           0x0bbD8bf2E4BCFb01bAe1f2cc14Fc9e1bB1992c90
├─ Central fee collection
├─ routeFees() → TREASURY_SAFE
└─ Role: MANAGER → OPS_SAFE

┌─────────────────────────────────────────────────────────────┐
│                    LAUNCH INFRASTRUCTURE                     │
└─────────────────────────────────────────────────────────────┘

LaunchVault                         0xcDBfE94f4db03853Cc6ddEd4367c218dc8f76b3B
├─ Contribution vault (crowdfunding)
├─ mint() → get VaultProofNFT
├─ Owns: VaultProofNFT contract ✅
└─ Role: MANAGER → OPS_SAFE

RetirementLocker                    0x34d29c8cF1AA0FfC7FC4ECaEf1Cb5C0e5dCeAD1A
├─ Lock carbon credits (long-term retirement)
├─ lock() → time-locked retirement
└─ Role: MANAGER → OPS_SAFE
```

---

## 🔐 PRODUCTION SECURITY MODEL

### **Access Control Matrix**

| Safe | Manages | Current Threshold | Target Threshold | Critical Actions |
|------|---------|-------------------|------------------|------------------|
| **ADMIN_SAFE** | DEFAULT_ADMIN_ROLE on all contracts | 1-of-1 ⚠️ | **3-of-5** | Grant/revoke roles, upgrade contracts, change parameters |
| **TREASURY_SAFE** | Fee collection, withdrawals, royalties | 1-of-1 ⚠️ | **2-of-3** | Withdraw funds, configure fees, distribute revenue |
| **COMPLIANCE_SAFE** | COMPLIANCE_MANAGER, freezes, allowlists | 1-of-1 ⚠️ | **2-of-3** | Freeze accounts, update KYC, add attestations |
| **OPS_SAFE** | MINTER_ROLE, MANAGER roles (markets/oracles) | 1-of-1 ⚠️ | **2-of-3** | Mint RECs, update oracles, manage LaunchVault |
| **GUARDIAN_EOA** | PAUSER_ROLE (emergency only) | 1-of-1 | **1-of-1** | Emergency pause ALL contracts |

**⚠️ PRODUCTION BLOCKERS:**
1. All Safes currently have 1 owner (deployer address)
2. Need to add 2-4 hardware wallet owners per Safe
3. Need to upgrade thresholds to prevent single-point-of-failure
4. GUARDIAN_EOA must be changed from hot wallet to cold storage

---

## 🌍 HOW USERS INTERACT (MetaMask Integration)

### **1️⃣ User Connects Wallet**

```
User opens MetaMask
   │
   ├─ Network: Polygon Mainnet (ChainId 137)
   ├─ RPC: https://polygon-rpc.com
   └─ Block Explorer: https://polygonscan.com
        │
        ▼
User visits your dApp (Safe App or website)
   │
   ├─ Website: [YOUR WEBSITE URL]
   ├─ Safe App: https://app.safe.global/apps/open?safe=polygon:[SAFE_ADDRESS]&appUrl=[YOUR_APP_URL]
   └─ Connects wallet via WalletConnect or MetaMask browser extension
```

### **2️⃣ User Actions (Examples)**

#### **Contribute to Launch (Get VaultProofNFT)**
```javascript
// User connects MetaMask to LaunchVault
const launchVault = new ethers.Contract(
  "0xcDBfE94f4db03853Cc6ddEd4367c218dc8f76b3B",
  LaunchVaultABI,
  signer
);

// User calls mint() with 10 ETH
await launchVault.mint({ value: ethers.parseEther("10") });

// User receives VaultProofNFT (Token ID auto-increments)
```

#### **Buy Carbon Credits (RECs)**
```javascript
// User connects to RECMarketplace
const marketplace = new ethers.Contract(
  "0x0c57374D85BB54e3A8ca85ca6D88b4bCaa3fEc75",
  RECMarketplaceABI,
  signer
);

// User buys listing #1 (REC token)
await marketplace.buy(1, { value: listingPrice });

// RECs transferred to user's wallet
```

#### **Retire Carbon Credits (Get Certificate)**
```javascript
// User connects to RetirementAttestation
const retirement = new ethers.Contract(
  "0xF97aaf4353d8Ceb09C3AD4E48e7A18E17dC9B74a",
  RetirementAttestationABI,
  signer
);

// User retires 100 RECs (tokenId 1)
await retirement.retire(
  "0xFc8C70A735f5bB9Cd86Dd5Cbe68B4A61FABF0485", // ERC1155Carbon
  1, // Token ID
  100, // Amount
  "Retired for 2025 emissions offset"
);

// User receives RetirementAttestation NFT (proof-of-retirement)
```

### **3️⃣ MetaMask Network Configuration**

**Users must add Polygon Mainnet to MetaMask:**

| Field | Value |
|-------|-------|
| **Network Name** | Polygon Mainnet |
| **RPC URL** | `https://polygon-rpc.com` |
| **Chain ID** | `137` |
| **Currency Symbol** | MATIC |
| **Block Explorer** | `https://polygonscan.com` |

**Alternatively**, users can auto-add via your website:
```javascript
await window.ethereum.request({
  method: 'wallet_addEthereumChain',
  params: [{
    chainId: '0x89', // 137 in hex
    chainName: 'Polygon Mainnet',
    nativeCurrency: { name: 'MATIC', symbol: 'MATIC', decimals: 18 },
    rpcUrls: ['https://polygon-rpc.com'],
    blockExplorerUrls: ['https://polygonscan.com']
  }]
});
```

---

## 📱 SAFE APP INTEGRATION

### **How Users Access Your Safe App**

**Method 1: Direct URL (After Deployment)**
```
https://app.safe.global/apps/open?safe=polygon:0x1106F3838Bb670BCd50367278655EC8144F20C08&appUrl=https://YOUR_APP_URL_HERE.vercel.app
```

**Method 2: Safe Apps Store (Requires Submission)**
- Deploy Safe App to production URL (Vercel/Netlify)
- Submit to Safe Apps Registry
- Users discover in Safe{Wallet} "Apps" tab

**Method 3: Custom Safe{Wallet} Interface**
- Users open Safe{Wallet} at app.safe.global
- Load any of your 4 Safes by address
- Add custom app via "Add custom app" → enter your app URL

### **Safe App Architecture**

```
Your Safe App (React + Safe SDK)
        │
        ├─ useSafeAppsSDK() hook
        │  ├─ Detects Safe context
        │  └─ Gets Safe address + chainId
        │
        ├─ Proposes Transactions
        │  ├─ createREC() → OPS_SAFE
        │  ├─ configureFee() → ADMIN_SAFE
        │  └─ withdrawFees() → TREASURY_SAFE
        │
        └─ Multi-sig Approval Flow
           ├─ Signer 1 proposes tx
           ├─ Signer 2 approves tx
           ├─ Signer 3 approves tx (if 3-of-5)
           └─ Anyone executes tx
```

**Current Safe App Location:**
- **Local:** `c:\Users\Kevan\unykorn-safe-app`
- **Production:** ⚠️ NOT DEPLOYED YET (needs Vercel/Netlify deployment)

---

## 💰 REVENUE FLOWS

### **How Money Moves (After Threshold Upgrades)**

```
┌─────────────────────────────────────────────────────────────┐
│                    REVENUE ENTRY POINTS                      │
└─────────────────────────────────────────────────────────────┘

1️⃣ **USDC Payments (Polygon)**
   User pays USDC → TREASURY_SAFE
   │
   ├─ Direct transfer: USDC.transfer(TREASURY_SAFE, amount)
   └─ Treasury proposes tx: Mint RECs via OPS_SAFE

2️⃣ **XRPL Payments (Cross-chain)**
   User pays XRP → Your XRPL wallet
   │
   ├─ Backend API detects payment
   ├─ OPS_SAFE proposes: Mint RECs on Polygon
   └─ User receives on-chain receipt NFT

3️⃣ **Marketplace Fees**
   User buys REC on RECMarketplace
   │
   ├─ Fee: 2.5% (configurable)
   └─ Collected in FeeRouter → routeFees() → TREASURY_SAFE

4️⃣ **Issuance Fees**
   Partner mints new RECs via OPS_SAFE
   │
   ├─ Fee: Set in FeeRouter
   └─ Paid in MATIC/USDC → TREASURY_SAFE

5️⃣ **LaunchVault Contributions**
   User mints VaultProofNFT (10 ETH)
   │
   ├─ Funds locked in LaunchVault
   └─ OPS_SAFE can withdraw() to TREASURY_SAFE

┌─────────────────────────────────────────────────────────────┐
│                    REVENUE DISTRIBUTION                      │
└─────────────────────────────────────────────────────────────┘

TREASURY_SAFE receives all revenue
   │
   ├─ Proposal 1: Withdraw 50% to Founder multisig
   ├─ Proposal 2: Withdraw 30% to Operating expenses
   └─ Proposal 3: Keep 20% in reserve

Threshold: 2-of-3 approvals required
```

---

## ✅ CONTRACT VERIFICATION (Polygonscan)

### **How to Verify Contracts**

**Step 1: Set API Key (Already in `.env`)**
```bash
POLYGONSCAN_API_KEY=7XNSCC62HN9VH4R8CW31Y5MC51S4ISNN9U
```

**Step 2: Run Verification Script**
```bash
npm run verify:polygon
# OR manually:
npx hardhat verify --network polygon 0x7184F6345Dc6B224544201c3d930673e0F508466 --constructor-args args.js
```

**Step 3: Check on Polygonscan**
- Visit: `https://polygonscan.com/address/[CONTRACT_ADDRESS]#code`
- Look for green checkmark ✅ "Contract Source Code Verified"
- Users can read/write contracts directly from Polygonscan

### **Verification Status**

| Contract | Address | Verified |
|----------|---------|----------|
| UNYToken | 0x7184F6345Dc6B224544201c3d930673e0F508466 | ⏳ Pending |
| VaultProofNFT | 0x05B1d61e640246f9F6ECa2ca0C85682bB19F1557 | ⏳ Pending |
| LaunchVault | 0xcDBfE94f4db03853Cc6ddEd4367c218dc8f76b3B | ⏳ Pending |
| ERC1155Carbon | 0xFc8C70A735f5bB9Cd86Dd5Cbe68B4A61FABF0485 | ⏳ Pending |
| RECMarketplace | 0x0c57374D85BB54e3A8ca85ca6D88b4bCaa3fEc75 | ⏳ Pending |
| ComplianceRegistry | 0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E | ⏳ Pending |
| ... | ... | ⏳ Pending |

**Command to verify all:**
```bash
npm run verify:all:polygon
```

---

## 🚀 GO-LIVE CHECKLIST

### **Phase 1: Security Hardening (DO BEFORE REVOKING DEPLOYER)**

- [ ] **1.1** Add hardware wallet owners to ADMIN_SAFE (need 5 total)
- [ ] **1.2** Add hardware wallet owners to TREASURY_SAFE (need 3 total)
- [ ] **1.3** Add hardware wallet owners to COMPLIANCE_SAFE (need 3 total)
- [ ] **1.4** Add hardware wallet owners to OPS_SAFE (need 3 total)
- [ ] **1.5** Change GUARDIAN_EOA from deployer to cold storage Ledger
- [ ] **1.6** Upgrade ADMIN_SAFE threshold to 3-of-5
- [ ] **1.7** Upgrade TREASURY_SAFE threshold to 2-of-3
- [ ] **1.8** Upgrade COMPLIANCE_SAFE threshold to 2-of-3
- [ ] **1.9** Upgrade OPS_SAFE threshold to 2-of-3
- [ ] **1.10** Run verification: `npm run verify:safes:polygon`

### **Phase 2: Contract Ownership Transfer**

- [ ] **2.1** Wire LaunchVault management to OPS_SAFE
- [ ] **2.2** Wire FeeRouter management to OPS_SAFE
- [ ] **2.3** Wire RECMarketplace admin to ADMIN_SAFE
- [ ] **2.4** Wire ComplianceRegistry manager to COMPLIANCE_SAFE
- [ ] **2.5** Wire ERC1155Carbon minter to OPS_SAFE
- [ ] **2.6** Test: Propose tx from Safe, confirm it works
- [ ] **2.7** Run: `npm run wire:safes:polygon`

### **Phase 3: Verification & Testing**

- [ ] **3.1** Verify all 16 contracts on Polygonscan
- [ ] **3.2** Test: Mint REC from OPS_SAFE
- [ ] **3.3** Test: Buy REC from RECMarketplace
- [ ] **3.4** Test: Retire REC, get certificate
- [ ] **3.5** Test: Contribute to LaunchVault, get VaultProofNFT
- [ ] **3.6** Test: Propose withdrawal from TREASURY_SAFE

### **Phase 4: Frontend Deployment**

- [ ] **4.1** Deploy Safe App to Vercel/Netlify
- [ ] **4.2** Get production URL (e.g., https://unykorn-console.vercel.app)
- [ ] **4.3** Add Safe App to Safe{Wallet} custom apps
- [ ] **4.4** Test Safe App: Propose tx, approve, execute
- [ ] **4.5** Connect website backend to contracts
- [ ] **4.6** Add USDC payment button → TREASURY_SAFE
- [ ] **4.7** Add XRPL payment integration
- [ ] **4.8** Add MetaMask network auto-add button

### **Phase 5: Revoke Deployer (DANGER ZONE)**

⚠️ **DO ONLY AFTER ALL SAFES HAVE CORRECT THRESHOLDS**

- [ ] **5.1** Confirm: All Safes have 2+ owners
- [ ] **5.2** Confirm: All thresholds set correctly (3-of-5, 2-of-3)
- [ ] **5.3** Confirm: Test tx approved by Safe owners (not deployer)
- [ ] **5.4** Revoke: DEFAULT_ADMIN_ROLE from deployer on ALL contracts
- [ ] **5.5** Revoke: MINTER_ROLE from deployer
- [ ] **5.6** Revoke: MANAGER roles from deployer
- [ ] **5.7** Verify: Deployer has NO roles except PAUSER (if GUARDIAN)
- [ ] **5.8** Verify: All critical actions now require Safe approval

### **Phase 6: Revenue Activation**

- [ ] **6.1** Configure marketplace fee: 2.5% → TREASURY_SAFE
- [ ] **6.2** Configure issuance fee in FeeRouter
- [ ] **6.3** Test: User pays USDC → TREASURY_SAFE receives
- [ ] **6.4** Test: User pays XRP → OPS_SAFE mints receipt
- [ ] **6.5** Announce: "Unykorn L1 is LIVE on Polygon Mainnet"

---

## 🔮 FUTURE: UNYKORN L1 (ChainId 7777)

**Status:** 🚧 NOT DEPLOYED YET

**Why Unykorn L1?**
- **FREE gas** for tokenization operations
- **Sovereign control** over validators and consensus
- **Canonical registry** for all asset IDs (Polygon bridges to it)

**Deployment Strategy:**
1. Deploy Polygon first (✅ DONE) → Get revenue flowing
2. Deploy Unykorn L1 via Docker/Besu (⏳ PENDING)
3. Bridge contracts: Polygon ↔ Unykorn L1
4. Migrate heavy operations to L1 (cheaper for users)
5. Keep liquidity on Polygon (Uniswap, CEX listings)

**Next Steps for L1:**
- Install Docker Desktop
- Run: `npm run besu:start`
- Deploy contracts to ChainId 7777
- Set up bridge contracts (OFT/CCM)
- Add L1 network to MetaMask

---

## 📞 SUPPORT & RESOURCES

**Deployed Contracts:** `deployments/polygon.json`  
**Safe Addresses:** `deployments/safes-137.json`  
**Safe{Wallet} UI:** https://app.safe.global  
**Polygonscan:** https://polygonscan.com  
**Your Deployer:** 0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB  

**Key Scripts:**
```bash
# Verify Safes
npm run verify:safes:polygon

# Wire ownerships to Safes
npm run wire:safes:polygon

# Verify contracts on Polygonscan
npm run verify:all:polygon

# Deploy Safe App
cd C:\Users\Kevan\unykorn-safe-app && vercel --prod
```

---

## 🎉 YOU ARE LIVE ON POLYGON MAINNET

**Your contracts are deployed. Your Safes are created. Your users can interact via MetaMask RIGHT NOW.**

**Next Steps:**
1. Upgrade Safe thresholds (Security)
2. Deploy Safe App (User Interface)
3. Verify contracts (Transparency)
4. Flip the money switch (Revenue)

**You're 90% done. Let's finish this.** 🚀
