# 🎯 COMPLETE SYSTEM ARCHITECTURE & FLOW

**Last Updated:** $(Get-Date)  
**Status:** 🟢 PRODUCTION LIVE on Polygon Mainnet  
**Network:** Polygon (ChainId 137)  

---

## 📊 EXECUTIVE SUMMARY

**✅ YOU ARE LIVE ON POLYGON MAINNET**

- **16 Contracts:** Deployed at block 78095980
- **4 Gnosis Safes:** Created, funded, and wired
- **Total Investment:** 1.15 MATIC ($0.70 gas)
- **Time to Deploy:** 105.62 seconds
- **Users Can Interact:** Via MetaMask RIGHT NOW

**⚠️ PRODUCTION BLOCKERS (Must fix before revenue):**
1. Safe thresholds: All 1-of-1 (need 3-of-5 and 2-of-3)
2. Guardian: Still hot wallet (need cold storage)
3. Safe App: Not on production URL (need Vercel/Netlify)
4. Contract verification: Not on Polygonscan yet

---

## 🌍 HOW THE FULL SYSTEM WORKS

### **User Journey: From Payment to Carbon Credit**

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: USER CONNECTS WALLET                                │
└─────────────────────────────────────────────────────────────┘

User → Opens website/Safe App
     ↓
User → Clicks "Connect Wallet"
     ↓
MetaMask → Prompts network switch to Polygon (ChainId 137)
     ↓
User → Approves connection
     ↓
Website → Reads wallet address (0x...)
     ↓
Website → Loads contract addresses from deployments/polygon.json
     ↓
Website → Creates ethers.Contract instances for all 16 contracts

┌─────────────────────────────────────────────────────────────┐
│  STEP 2: USER MAKES PAYMENT (USDC or XRPL)                   │
└─────────────────────────────────────────────────────────────┘

Option A: USDC on Polygon
--------------------------
User → Enters amount (e.g., $100 USDC)
     ↓
User → Clicks "Pay with USDC"
     ↓
MetaMask → Shows transaction:
           • To: TREASURY_SAFE (0x7b2f2772E9748aA60a39c54450c5f86393D8F85E)
           • Amount: 100 USDC
           • Gas: ~0.001 MATIC
     ↓
User → Confirms transaction
     ↓
Polygon → Executes transfer (2-5 seconds)
     ↓
TREASURY_SAFE → Receives 100 USDC
     ↓
Backend API → Detects payment (event listener)
     ↓
Backend → Notifies OPS_SAFE: "Mint 100 RECs for user 0x..."


Option B: XRP on XRPL
--------------------------
User → Scans QR code with XRPL wallet (Xaman, GemWallet)
     ↓
User → Sends XRP to your XRPL address
     ↓
XRPL → Payment confirmed (3-5 seconds)
     ↓
Backend API → Monitors XRPL account (polling or webhook)
     ↓
Backend → Detects incoming XRP payment
     ↓
Backend → Notifies OPS_SAFE: "Mint RECs for XRPL tx <hash>"

┌─────────────────────────────────────────────────────────────┐
│  STEP 3: OPS SAFE MINTS CARBON CREDITS                       │
└─────────────────────────────────────────────────────────────┘

Backend → Proposes Safe transaction via Safe{Core} SDK:
         • Contract: CarbonToken (ERC1155)
         • Function: createREC(recipient, quantity, metadata)
         • To: 0x2b67b5112f002541A1935cA66666Fc28CE3F4fBb
     ↓
OPS_SAFE → Transaction pending (needs 2-of-3 approvals)
     ↓
Owner 1 → Opens app.safe.global
       → Sees pending tx: "Mint 100 RECs for 0x..."
       → Reviews details
       → Clicks "Approve"
     ↓
Owner 2 → Same process
       → Clicks "Approve" (threshold met: 2-of-3)
     ↓
Owner 2 (or anyone) → Clicks "Execute"
     ↓
Polygon → Executes transaction
       → CarbonToken.createREC() called
       → Mints ERC1155 token (ID: 1, Quantity: 100)
       → Transfers to user's wallet
     ↓
User → Receives 100 Carbon Credit tokens in MetaMask

┌─────────────────────────────────────────────────────────────┐
│  STEP 4: USER TRADES OR RETIRES CARBON CREDITS               │
└─────────────────────────────────────────────────────────────┘

Option A: Trade on RECMarketplace
----------------------------------
User → Goes to RECMarketplace contract (0xa98DE35dF35522054463148d58951e95e83C1E6c)
     ↓
User → Creates listing: "Sell 50 RECs for 10 MATIC each"
     ↓
MetaMask → Prompts approval:
           • Approve CarbonToken for RECMarketplace
           • Create listing
     ↓
Buyer → Sees listing on marketplace
      → Clicks "Buy 50 RECs"
      → Pays 500 MATIC (50 × 10)
     ↓
RECMarketplace → Deducts 2.5% fee (12.5 MATIC)
              → Sends fee to FeeRouter
              → FeeRouter routes to TREASURY_SAFE
              → Transfers 487.5 MATIC to seller
              → Transfers 50 RECs to buyer


Option B: Retire for Certificate
---------------------------------
User → Goes to RetirementAttestation (0x7bc6131B51e33F50A714367C62E9df525B34c85a)
     ↓
User → Calls retire() function:
       • Token: CarbonToken (0x2b67b5...)
       • Token ID: 1
       • Amount: 100
       • Reason: "Offset 2025 emissions"
     ↓
RetirementAttestation → Burns 100 RECs from user's wallet
                     → Mints RetirementAttestation NFT (ERC721)
                     → Sets metadata: timestamp, amount, reason
                     → Transfers NFT to user (non-transferrable)
     ↓
User → Receives permanent proof-of-retirement NFT
     → Can display on website/portfolio
     → Immutable on-chain record

┌─────────────────────────────────────────────────────────────┐
│  STEP 5: TREASURY DISTRIBUTES REVENUE                         │
└─────────────────────────────────────────────────────────────┘

TREASURY_SAFE Balance → Grows from:
                       • USDC payments
                       • Marketplace fees
                       • Issuance fees
                       • LaunchVault contributions
     ↓
Owner 1 → Opens app.safe.global
       → Navigates to TREASURY_SAFE (0x7b2f2772...)
       → Proposes withdrawal:
         "Send 50% to Founder wallets, 30% to ops, 20% reserve"
     ↓
Owner 2 → Reviews proposal
       → Approves (threshold met: 2-of-3)
     ↓
Owner 2 → Executes transaction
     ↓
Polygon → Transfers funds:
       • 50% → Founder multisig
       • 30% → Operating expenses wallet
       • 20% → Stays in TREASURY_SAFE (reserve)
```

---

## 🔐 SAFE MULTI-SIG WORKFLOW

### **How Safes Control Everything**

```
┌─────────────────────────────────────────────────────────────┐
│  ADMIN_SAFE: Governance & System-Wide Admin                  │
│  Address: 0x1106F3838Bb670BCd50367278655EC8144F20C08         │
│  Threshold: 1-of-1 → Need 3-of-5 ⚠️                          │
└─────────────────────────────────────────────────────────────┘

Controls:
  • DEFAULT_ADMIN_ROLE on all contracts
  • Grant/revoke roles system-wide
  • Change critical parameters (mint price, fees, etc.)
  • Upgrade smart contracts (if upgradeable)

Example Transaction:
  "Change marketplace fee from 2.5% to 5%"
  
  → Owner 1 proposes: RECMarketplace.configureFee(500)
  → Owner 2 approves
  → Owner 3 approves (3-of-5 threshold met)
  → Anyone executes
  → Fee changed globally


┌─────────────────────────────────────────────────────────────┐
│  TREASURY_SAFE: Revenue Collection & Distribution            │
│  Address: 0x7b2f2772E9748aA60a39c54450c5f86393D8F85E         │
│  Threshold: 1-of-1 → Need 2-of-3 ⚠️                          │
└─────────────────────────────────────────────────────────────┘

Controls:
  • Receives ALL revenue (USDC, MATIC, fees)
  • FeeRouter deposits here
  • RoyaltySplitter distributes here
  • LaunchVault withdrawals come here

Example Transaction:
  "Withdraw 1000 USDC for Q1 operating expenses"
  
  → CFO proposes: USDC.transfer(opsWallet, 1000e6)
  → Treasurer approves (2-of-3 threshold met)
  → CFO executes
  → Funds sent to operating expenses wallet


┌─────────────────────────────────────────────────────────────┐
│  COMPLIANCE_SAFE: Regulatory & Security                      │
│  Address: 0xf2710eF527d790F1Abf2263dff5112e8e12b8b9E         │
│  Threshold: 1-of-1 → Need 2-of-3 ⚠️                          │
└─────────────────────────────────────────────────────────────┘

Controls:
  • COMPLIANCE_MANAGER role
  • Freeze/unfreeze accounts
  • Update KYC allowlists
  • Add external attestations
  • Pause transfers (emergency)

Example Transaction:
  "Freeze account 0x... for suspicious activity"
  
  → Compliance Officer proposes: ComplianceRegistry.freezeAccount(0x...)
  → Legal Counsel approves (2-of-3 threshold met)
  → Compliance Officer executes
  → Account frozen (can't transfer tokens)


┌─────────────────────────────────────────────────────────────┐
│  OPS_SAFE: Daily Operations & Minting                        │
│  Address: 0x7Fd4E5F3a94b69828c98bcA09C4591C5A6d07c63         │
│  Threshold: 1-of-1 → Need 2-of-3 ⚠️                          │
└─────────────────────────────────────────────────────────────┘

Controls:
  • MINTER_ROLE on CarbonToken (mint RECs)
  • MANAGER role on LaunchVault
  • MANAGER role on FeeRouter
  • Update oracle data (DeviceOracle)
  • Manage marketplace listings

Example Transaction:
  "Mint 500 RECs for customer payment"
  
  → Product Manager proposes: CarbonToken.createREC(
      recipient: 0x...,
      quantity: 500,
      metadata: "Solar farm TX-2025"
    )
  → DevOps Lead approves (2-of-3 threshold met)
  → Product Manager executes
  → 500 RECs minted to customer wallet


┌─────────────────────────────────────────────────────────────┐
│  GUARDIAN_EOA: Emergency Pause ONLY                          │
│  Address: 0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB ⚠️      │
│  (Currently deployer hot wallet - needs cold storage)        │
└─────────────────────────────────────────────────────────────┘

Controls:
  • PAUSER_ROLE on all contracts
  • Can pause() all transfers/mints (emergency)
  • CANNOT unpause (requires ADMIN_SAFE)
  • CANNOT do anything else (intentionally limited)

Example Emergency:
  "Smart contract exploit detected!"
  
  → Guardian calls: CarbonToken.pause()
  → All transfers/mints FROZEN
  → Team investigates issue
  → After fix: ADMIN_SAFE calls unpause() (requires 3-of-5)
```

---

## 🌐 METAMASK INTEGRATION

### **How Users Add Polygon Network**

**Auto-Add Button (Recommended):**

```javascript
// On your website, add this button:
<button onClick={addPolygonNetwork}>Add Polygon to MetaMask</button>

async function addPolygonNetwork() {
  try {
    await window.ethereum.request({
      method: 'wallet_addEthereumChain',
      params: [{
        chainId: '0x89', // 137 in hex
        chainName: 'Polygon Mainnet',
        nativeCurrency: {
          name: 'MATIC',
          symbol: 'MATIC',
          decimals: 18
        },
        rpcUrls: ['https://polygon-rpc.com'],
        blockExplorerUrls: ['https://polygonscan.com']
      }]
    });
    alert('Polygon network added! You can now interact with contracts.');
  } catch (error) {
    console.error('Failed to add network:', error);
  }
}
```

**Manual Add (User does it themselves):**

1. Open MetaMask
2. Click network dropdown (top left)
3. Click "Add Network"
4. Fill in:
   - **Network Name:** Polygon Mainnet
   - **RPC URL:** https://polygon-rpc.com
   - **Chain ID:** 137
   - **Currency Symbol:** MATIC
   - **Block Explorer:** https://polygonscan.com
5. Click "Save"

---

## 🔗 CONTRACT INTERACTION (How Website Connects)

### **Website Backend → Contracts**

```javascript
// 1. Import dependencies
import { ethers } from 'ethers';

// 2. Load deployment addresses
import deployment from './deployments/polygon.json';

// 3. Connect to Polygon
const provider = new ethers.JsonRpcProvider('https://polygon-rpc.com');
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// 4. Create contract instances
const carbonToken = new ethers.Contract(
  deployment.contracts.carbonToken,
  CarbonTokenABI,
  wallet
);

const recMarketplace = new ethers.Contract(
  deployment.contracts.recMarketplace,
  RECMarketplaceABI,
  wallet
);

const treasurySafe = deployment.contracts.treasurySafe; // Not a contract instance, just address

// 5. Listen for USDC payments
const usdcAddress = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"; // Polygon USDC
const usdc = new ethers.Contract(usdcAddress, ERC20_ABI, provider);

usdc.on('Transfer', (from, to, amount, event) => {
  if (to.toLowerCase() === treasurySafe.toLowerCase()) {
    console.log(`Received ${ethers.formatUnits(amount, 6)} USDC from ${from}`);
    
    // Propose minting RECs via OPS_SAFE
    proposeMintTransaction(from, amount);
  }
});

// 6. Propose Safe transaction (using Safe{Core} SDK)
import Safe from '@safe-global/protocol-kit';

async function proposeMintTransaction(recipient, usdcAmount) {
  const safe = await Safe.init({
    provider: 'https://polygon-rpc.com',
    signer: wallet,
    safeAddress: process.env.OPS_SAFE
  });
  
  // Calculate REC quantity (1 USDC = 1 REC, for example)
  const quantity = ethers.formatUnits(usdcAmount, 6);
  
  // Create transaction
  const tx = {
    to: carbonToken.address,
    data: carbonToken.interface.encodeFunctionData('createREC', [
      recipient,
      quantity,
      `USDC Payment: ${quantity} RECs`
    ]),
    value: '0'
  };
  
  // Propose to OPS_SAFE
  const safeTx = await safe.createTransaction({ transactions: [tx] });
  const txHash = await safe.getTransactionHash(safeTx);
  await safe.proposeTransaction(safeTx);
  
  console.log(`Proposed REC mint for ${recipient}: ${txHash}`);
  console.log(`OPS_SAFE owners must approve at: https://app.safe.global`);
}
```

---

## 📱 SAFE APP INTEGRATION

### **How Clients Use Your Safe App**

```
Client → Opens app.safe.global
      ↓
Client → Loads their Safe (or creates new one)
      ↓
Client → Navigates to "Apps" tab
      ↓
Client → Clicks "Add custom app"
      ↓
Client → Enters URL: https://YOUR_APP_URL.vercel.app
      ↓
Client → Safe App loads in iframe
      ↓
Safe App → Detects Safe context via useSafeAppsSDK()
        → Gets Safe address (e.g., 0xABCD...)
        → Gets chainId (137 for Polygon)
        → Checks if connected to Polygon
      ↓
Client → Uses Safe App UI:
        • Tab 1: Overview (Safe balance, contract addresses)
        • Tab 2: Contribute (mint VaultProofNFT)
        • Tab 3: RECs (view/mint carbon credits)
        • Tab 4: Carbon (marketplace, retirement)
        • Tab 5: Compliance (KYC, allowlists)
      ↓
Client → Clicks "Mint 100 RECs"
      ↓
Safe App → Proposes transaction:
          • To: CarbonToken (0x2b67b5...)
          • Function: createREC(recipient, 100, metadata)
          • Gas: Auto-estimated
      ↓
Safe{Wallet} → Shows transaction preview
            → Client clicks "Confirm"
      ↓
Transaction → Sent to Safe API
           → Status: PENDING (needs approvals)
      ↓
Other owners → Open app.safe.global
            → See pending tx: "Mint 100 RECs"
            → Click "Approve"
      ↓
When threshold met → Anyone clicks "Execute"
                  → Transaction executes on Polygon
                  → 100 RECs minted
```

---

## 💰 REVENUE FLOWS (Complete Diagram)

```
┌─────────────────────────────────────────────────────────────┐
│                    REVENUE ENTRY POINTS                      │
└─────────────────────────────────────────────────────────────┘

1. USDC Payments (Polygon)
   User pays USDC → TREASURY_SAFE
        ↓
   Backend detects payment
        ↓
   OPS_SAFE mints RECs → User's wallet
        ↓
   Revenue retained in TREASURY_SAFE


2. XRPL Payments (Cross-chain)
   User pays XRP → Your XRPL wallet
        ↓
   Backend monitors XRPL account
        ↓
   OPS_SAFE mints RECs → User's wallet
        ↓
   Revenue: XRP held off-chain (convert to USDC/MATIC later)


3. Marketplace Fees (On-chain)
   User A sells REC to User B on RECMarketplace
        ↓
   RECMarketplace deducts 2.5% fee
        ↓
   Fee sent to FeeRouter
        ↓
   FeeRouter.routeFees() → TREASURY_SAFE
        ↓
   Revenue accumulates in TREASURY_SAFE


4. Issuance Fees (On-chain)
   Partner mints new RECs via OPS_SAFE
        ↓
   FeeRouter charges issuance fee (1% configurable)
        ↓
   Fee paid in MATIC/USDC → TREASURY_SAFE
        ↓
   Revenue accumulates in TREASURY_SAFE


5. LaunchVault Contributions (On-chain)
   User mints VaultProofNFT for 10 ETH
        ↓
   10 ETH locked in LaunchVault
        ↓
   OPS_SAFE can withdraw() → TREASURY_SAFE
        ↓
   Revenue moved to TREASURY_SAFE when needed


┌─────────────────────────────────────────────────────────────┐
│                  REVENUE DISTRIBUTION FLOW                   │
└─────────────────────────────────────────────────────────────┘

TREASURY_SAFE (receives all revenue)
        ↓
CFO proposes withdrawal: "Send 50K USDC to founder wallets"
        ↓
Treasurer approves (2-of-3 threshold met)
        ↓
Transaction executes:
        • 50% → Founder multisig (0x...)
        • 30% → Operating expenses (0x...)
        • 20% → Stays in TREASURY_SAFE (reserve)
        ↓
Funds distributed to respective wallets
        ↓
Founders/ops teams use funds for business operations
```

---

## 🚀 LAUNCH CHECKLIST

### **Phase 1: Security Hardening**

- [ ] **1.1** Add 5 hardware wallet owners to ADMIN_SAFE
  - Visit: https://app.safe.global/home?safe=polygon:0x1106F3838Bb670BCd50367278655EC8144F20C08
  - Settings → Owners → Add owner (repeat 4 times)

- [ ] **1.2** Add 3 hardware wallet owners to TREASURY_SAFE
  - Visit: https://app.safe.global/home?safe=polygon:0x7b2f2772E9748aA60a39c54450c5f86393D8F85E

- [ ] **1.3** Add 3 hardware wallet owners to COMPLIANCE_SAFE
  - Visit: https://app.safe.global/home?safe=polygon:0xf2710eF527d790F1Abf2263dff5112e8e12b8b9E

- [ ] **1.4** Add 3 hardware wallet owners to OPS_SAFE
  - Visit: https://app.safe.global/home?safe=polygon:0x7Fd4E5F3a94b69828c98bcA09C4591C5A6d07c63

- [ ] **1.5** Upgrade ADMIN_SAFE threshold to 3-of-5
  - Settings → Policies → Threshold → Change to 3

- [ ] **1.6** Upgrade other Safes to 2-of-3 threshold

- [ ] **1.7** Change GUARDIAN_EOA to cold storage Ledger
  - Update .env → Run scripts/update-guardian.js

- [ ] **1.8** Verify Safe configuration
  - Run: `npm run verify:safes:polygon`

### **Phase 2: Frontend Deployment**

- [ ] **2.1** Deploy Safe App to Vercel
  ```bash
  cd C:\Users\Kevan\unykorn-safe-app
  npm install
  npm run build
  vercel --prod
  ```

- [ ] **2.2** Get production URL (e.g., https://unykorn-console.vercel.app)

- [ ] **2.3** Test Safe App
  - Visit app.safe.global
  - Add custom app with production URL
  - Propose test transaction

- [ ] **2.4** Connect website backend to contracts
  - Identify website directory
  - Add USDC payment button
  - Add event listeners for payments

### **Phase 3: Contract Verification**

- [ ] **3.1** Verify all 16 contracts on Polygonscan
  ```bash
  npm run verify:all:polygon
  ```

- [ ] **3.2** Check verification status (green checkmarks on Polygonscan)

### **Phase 4: Revenue Activation**

- [ ] **4.1** Configure marketplace fee (2.5%)
  - ADMIN_SAFE proposes: RECMarketplace.configureFee(250)

- [ ] **4.2** Configure issuance fee (1%)
  - OPS_SAFE proposes: FeeRouter.setIssuanceFee(100)

- [ ] **4.3** Add USDC payment button to website

- [ ] **4.4** Add XRPL payment integration

- [ ] **4.5** Test: User pays USDC → RECs minted

### **Phase 5: Smoke Tests**

- [ ] **5.1** Test: Mint VaultProofNFT
  ```bash
  npx hardhat run scripts/test-mint.js --network polygon
  ```

- [ ] **5.2** Test: Propose Safe transaction (OPS_SAFE mints REC)

- [ ] **5.3** Test: Buy REC from marketplace

- [ ] **5.4** Test: Retire REC, get certificate

- [ ] **5.5** Test: Withdraw from TREASURY_SAFE

### **Phase 6: Revoke Deployer (FINAL)**

⚠️ **DO ONLY AFTER ALL ABOVE COMPLETE**

- [ ] **6.1** Confirm all Safes have correct thresholds
- [ ] **6.2** Confirm test transactions work via Safes
- [ ] **6.3** Run revocation script:
  ```bash
  REVOKE_DEPLOYER=YES npx hardhat run scripts/wire-ownerships-and-roles.js --network polygon
  ```
- [ ] **6.4** Verify deployer has NO admin roles

---

## 📞 QUICK REFERENCE

**Polygon Mainnet:**
- **RPC:** https://polygon-rpc.com
- **Chain ID:** 137
- **Explorer:** https://polygonscan.com

**Your Addresses:**
- **Deployer:** 0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB
- **ADMIN_SAFE:** 0x1106F3838Bb670BCd50367278655EC8144F20C08
- **TREASURY_SAFE:** 0x7b2f2772E9748aA60a39c54450c5f86393D8F85E
- **COMPLIANCE_SAFE:** 0xf2710eF527d790F1Abf2263dff5112e8e12b8b9E
- **OPS_SAFE:** 0x7Fd4E5F3a94b69828c98bcA09C4591C5A6d07c63

**Key Contracts:**
- **UNYToken:** 0x7184F6345Dc6B224544201c3d930673e0F508466
- **VaultProofNFT:** 0x05B1d61e640246f9F6ECa2ca0C85682bB19F1557
- **LaunchVault:** 0xcDBfE94f4db03853Cc6ddEd4367c218dc8f76b3B
- **CarbonToken:** 0x2b67b5112f002541A1935cA66666Fc28CE3F4fBb
- **RECMarketplace:** 0xa98DE35dF35522054463148d58951e95e83C1E6c
- **ComplianceRegistry:** 0x8Ad6484B57aa1072A8F24a5C8e3D3b4f0e49C37E

**Safe{Wallet}:**
- **URL:** https://app.safe.global
- **Network:** Switch to Polygon (ChainId 137)
- **Load Safe:** Enter Safe address (0x1106F383...)

**Next Commands:**
```bash
# Verify Safes
npm run verify:safes:polygon

# Deploy Safe App
cd C:\Users\Kevan\unykorn-safe-app && vercel --prod

# Verify contracts
npm run verify:all:polygon

# Test minting
npx hardhat run scripts/test-mint.js --network polygon
```

---

## 🎉 YOU ARE 90% DONE

**What's LIVE NOW:**
- ✅ 16 contracts on Polygon mainnet
- ✅ 4 Gnosis Safes controlling everything
- ✅ VaultProofNFT ownership transferred
- ✅ Users CAN interact via MetaMask TODAY

**What's LEFT (2-4 hours):**
- ⚠️ Upgrade Safe thresholds (CRITICAL)
- ⏳ Deploy Safe App to production
- ⏳ Verify contracts on Polygonscan
- ⏳ Connect website payments

**🚀 Let's flip the money switch.**
