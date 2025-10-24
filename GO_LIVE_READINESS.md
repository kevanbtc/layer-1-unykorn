# 🚀 GO-LIVE READINESS CHECKLIST

**Mission:** Launch Unykorn L1 (ChainId 7777) as the canonical registry for all tokenization, with Safe{Core} as the control layer and Sonny as the AI front door.

**Target Date:** _____________  
**Approval:** _____________  
**Go/No-Go Decision:** _____________

---

## ⚡ 30-Minute Go/No-Go Gate (MUST PASS)

### Critical Decisions

- [ ] **Governance Ready**
  - [ ] 4 production Safes exist on 7777
  - [ ] ADMIN_SAFE (3-of-5): All 5 hardware wallet owners confirmed
  - [ ] TREASURY_SAFE (2-of-3): All 3 hardware wallet owners confirmed
  - [ ] COMPLIANCE_SAFE (2-of-3): All 3 hardware wallet owners confirmed
  - [ ] OPS_SAFE (2-of-3): All 3 hardware wallet owners confirmed
  - [ ] All thresholds verified on-chain
  - [ ] Test signature collection completed (2-of-3, 3-of-5)

- [ ] **Canonical Decision Published**
  - [ ] "Unykorn L1 (7777) = source of truth" in internal runbook
  - [ ] Canonical policy published on unykorn.org
  - [ ] All team members briefed and aligned

- [ ] **Risk Rails Tested**
  - [ ] GUARDIAN_EOA tested (pause → unpause) on sacrificial contract
  - [ ] Audit note recorded with transaction hash
  - [ ] Emergency contact list confirmed (phone/email/pager)
  - [ ] Incident response playbook printed and distributed

**GO/NO-GO:** If ANY checkbox above is unchecked, **DO NOT PROCEED**

---

## 🔧 Phase 1: Infrastructure (Week 1)

### L1 Node Operations

- [ ] **Start Unykorn L1**
  ```powershell
  cd "c:\Users\Kevan\layer 1 build"
  .\scripts\unykorn.ps1 besu-init  # First time only
  .\scripts\unykorn.ps1 besu-up    # Start nodes
  ```

- [ ] **Verify RPC Endpoint**
  ```powershell
  .\scripts\unykorn.ps1 test-rpc   # Should return OK at http://127.0.0.1:8545
  Test-NetConnection 127.0.0.1 -Port 8545  # Should return True
  ```

- [ ] **Confirm ChainId**
  ```powershell
  npx hardhat console --network unykorn
  ```
  ```javascript
  (await ethers.provider.getNetwork()).chainId  // Must be 7777n
  ```

**Expected:** RPC returns 200 OK, chainId = 7777, no connection errors

---

### Deploy Core Contracts (FREE GAS!)

- [ ] **Deploy 16-Contract Suite**
  ```powershell
  npm run deploy:energy:unykorn
  ```

- [ ] **Verify Deployment**
  - [ ] UNYToken deployed: `0x...`
  - [ ] ComplianceRegistry deployed: `0x...`
  - [ ] VaultProofNFT deployed: `0x...`
  - [ ] LaunchVault deployed: `0x...`
  - [ ] All 16 contracts in `deployments/unykorn.json`
  - [ ] Total cost: **$0.00 (FREE GAS)** ✅
  - [ ] Deployment time: ~30-60 seconds

- [ ] **Record Addresses**
  - [ ] Add all contract addresses to `.env`
  - [ ] Update internal documentation
  - [ ] Share with team via secure channel

**Expected:** 16 contracts deployed, verified on Sourcify, zero gas cost

---

## 🔐 Phase 2: Safe Infrastructure (Week 1-2)

### Deploy Safe Contracts

- [ ] **Clone Safe Deployment Repo**
  ```powershell
  cd "c:\Users\Kevan"
  git clone https://github.com/safe-global/safe-smart-account.git
  cd safe-smart-account
  npm install
  ```

- [ ] **Deploy to ChainId 7777**
  ```powershell
  npx hardhat deploy --network unykorn
  ```

- [ ] **Verify Safe Contracts**
  - [ ] Safe Singleton: `0x...`
  - [ ] Safe Proxy Factory: `0x...`
  - [ ] Fallback Handler: `0x...`
  - [ ] MultiSend Library: `0x...`
  - [ ] All verified on Sourcify

---

### Stand Up Safe Services

- [ ] **Clone Safe Infrastructure**
  ```powershell
  cd "c:\Users\Kevan"
  git clone https://github.com/safe-global/safe-infrastructure.git
  cd safe-infrastructure
  ```

- [ ] **Configure for ChainId 7777**
  - [ ] Edit `docker-compose.yml` (add Unykorn L1 service)
  - [ ] Set `ETHEREUM_RPC_URL=http://host.docker.internal:8545`
  - [ ] Set `CHAIN_ID=7777`
  - [ ] Configure event indexing (not tracing)

- [ ] **Start Services**
  ```powershell
  docker-compose up -d
  ```

- [ ] **Verify Services Running**
  - [ ] Transaction Service: `http://localhost:8001`
  - [ ] Events Service: `http://localhost:8002`
  - [ ] Config Service: `http://localhost:8003`
  - [ ] Client Gateway: `http://localhost:8004`

- [ ] **Test Client Gateway**
  ```powershell
  curl http://localhost:8004/v1/chains/7777/about
  ```
  **Expected:** 200 OK with chain metadata

---

### Create Production Safes

- [ ] **Prepare Hardware Wallets**
  - [ ] 5 Ledgers for ADMIN_SAFE (initialized, firmware updated)
  - [ ] 3 Ledgers for TREASURY_SAFE
  - [ ] 3 Ledgers for COMPLIANCE_SAFE
  - [ ] 3 Ledgers for OPS_SAFE
  - [ ] 1 Ledger for GUARDIAN_EOA (cold storage, offline backup)

- [ ] **Deploy ADMIN_SAFE (3-of-5)**
  - [ ] Owners: Founder1, Founder2, Founder3, Legal, CTO
  - [ ] Threshold: 3
  - [ ] Address recorded: `0x...`
  - [ ] Test signature collection (3 signatures required)

- [ ] **Deploy TREASURY_SAFE (2-of-3)**
  - [ ] Owners: CFO, Treasurer, Founder1
  - [ ] Threshold: 2
  - [ ] Address recorded: `0x...`

- [ ] **Deploy COMPLIANCE_SAFE (2-of-3)**
  - [ ] Owners: Compliance Officer, Legal, External Auditor
  - [ ] Threshold: 2
  - [ ] Address recorded: `0x...`

- [ ] **Deploy OPS_SAFE (2-of-3)**
  - [ ] Owners: CTO, DevOps Lead, Product Manager
  - [ ] Threshold: 2
  - [ ] Address recorded: `0x...`

- [ ] **Record GUARDIAN_EOA**
  - [ ] Address: `0x...`
  - [ ] Owner: Founder (hardware wallet, cold storage)
  - [ ] Purpose: Emergency pause ONLY

- [ ] **Update .env**
  ```env
  ADMIN_SAFE=0x...
  TREASURY_SAFE=0x...
  COMPLIANCE_SAFE=0x...
  OPS_SAFE=0x...
  GUARDIAN_EOA=0x...
  ```

---

## 🔄 Phase 3: Wire Ownerships & Roles (Week 2)

### Transfer Control to Safes

- [ ] **Run Wire Script**
  ```powershell
  npm run wire:safes:unykorn
  ```

- [ ] **Verify Ownership Transfers (ON-CHAIN)**
  ```powershell
  npx hardhat console --network unykorn
  ```

  **VaultProofNFT → LaunchVault:**
  ```javascript
  const VaultProofNFT = await ethers.getContractAt("VaultProofNFT", "0x...");
  await VaultProofNFT.owner(); // Should be LaunchVault address
  ```

  **ComplianceRegistry → COMPLIANCE_SAFE:**
  ```javascript
  const ComplianceRegistry = await ethers.getContractAt("ComplianceRegistry", "0x...");
  await ComplianceRegistry.owner(); // Should be COMPLIANCE_SAFE
  ```

  **LaunchVault → OPS_SAFE:**
  ```javascript
  const LaunchVault = await ethers.getContractAt("LaunchVault", "0x...");
  await LaunchVault.owner(); // Should be OPS_SAFE
  ```

  **RoyaltySplitter → TREASURY_SAFE:**
  ```javascript
  const RoyaltySplitter = await ethers.getContractAt("RoyaltySplitter", "0x...");
  await RoyaltySplitter.owner(); // Should be TREASURY_SAFE
  ```

- [ ] **Verify Role Grants**
  ```javascript
  const LaunchVault = await ethers.getContractAt("LaunchVault", "0x...");
  const adminRole = await LaunchVault.DEFAULT_ADMIN_ROLE();
  await LaunchVault.hasRole(adminRole, process.env.ADMIN_SAFE); // Should be true
  await LaunchVault.hasRole(adminRole, DEPLOYER_ADDRESS); // Should be FALSE
  ```

- [ ] **Verify Fee Recipients**
  ```javascript
  const FeeRouter = await ethers.getContractAt("FeeRouter", "0x...");
  await FeeRouter.recipient(); // Should be TREASURY_SAFE
  ```

- [ ] **CRITICAL: Verify Deployer Has NO Authority**
  - [ ] NO ownership on any contract
  - [ ] NO admin roles (DEFAULT_ADMIN_ROLE, MINTER_ROLE, PAUSER_ROLE)
  - [ ] NO special privileges

**Expected:** All contracts controlled by Safes, deployer fully revoked

---

## 🧪 Phase 4: Smoke Tests (Week 3)

### Test 1: Contribution Flow

- [ ] **Execute Test**
  ```javascript
  const LaunchVault = await ethers.getContractAt("LaunchVault", "0x...");
  const VaultProofNFT = await ethers.getContractAt("VaultProofNFT", "0x...");
  const [signer] = await ethers.getSigners();
  
  // Contribute 10 UNYETH
  const tx = await LaunchVault.contribute({ value: ethers.parseEther("10") });
  await tx.wait();
  
  // Check NFT minted
  const balance = await VaultProofNFT.balanceOf(signer.address);
  console.log("NFT Balance:", balance.toString()); // Should be 1
  ```

- [ ] **Expected Result:** NFT automatically minted (LaunchVault is owner of VaultProofNFT)

---

### Test 2: REC Lifecycle (Mint → List → Buy → Retire)

- [ ] **Mint REC (OPS_SAFE signs)**
  - [ ] OPS_SAFE prepares mint transaction
  - [ ] 2-of-3 signatures collected
  - [ ] Transaction executes
  - [ ] REC token minted

- [ ] **List on RECMarketplace (User transaction)**
  - [ ] User lists REC for sale
  - [ ] Marketplace fee (0.10% maker) sent to TREASURY_SAFE

- [ ] **Buy REC (Buyer transaction)**
  - [ ] Buyer purchases REC
  - [ ] Marketplace fee (0.25% taker) sent to TREASURY_SAFE

- [ ] **Retire REC (User transaction)**
  - [ ] User burns REC token
  - [ ] RetirementAttestation emitted (COMPLIANCE_SAFE verifies)
  - [ ] Immutable retirement record on-chain

- [ ] **Expected Result:** Complete REC flow with fee routing to TREASURY_SAFE

---

### Test 3: Compliance Gate

- [ ] **Block Sanctioned Address**
  ```javascript
  const ComplianceRegistry = await ethers.getContractAt("ComplianceRegistry", "0x...");
  const UNYToken = await ethers.getContractAt("UNYToken", "0x...");
  
  // COMPLIANCE_SAFE blocks address
  await ComplianceRegistry.connect(COMPLIANCE_SAFE_SIGNER).blockAddress("0xBAD_ADDRESS");
  
  // Try to transfer (should fail)
  try {
    await UNYToken.transfer("0xBAD_ADDRESS", ethers.parseEther("1"));
    console.log("❌ FAIL: Transfer succeeded (should have been blocked)");
  } catch (error) {
    console.log("✅ PASS: Transfer blocked by compliance");
  }
  ```

- [ ] **Allow Clean Address**
  ```javascript
  // Clean address transfer succeeds
  await UNYToken.transfer("0xCLEAN_ADDRESS", ethers.parseEther("1"));
  console.log("✅ PASS: Clean transfer succeeded");
  ```

- [ ] **Expected Result:** Sanctioned addresses blocked, clean addresses pass

---

### Test 4: Fee Routing

- [ ] **Execute Marketplace Trade**
  - [ ] User buys REC on marketplace
  - [ ] Fee collected

- [ ] **Verify Fee in TREASURY_SAFE**
  ```javascript
  const balance = await ethers.provider.getBalance(process.env.TREASURY_SAFE);
  console.log("TREASURY_SAFE balance:", ethers.formatEther(balance));
  ```

- [ ] **Expected Result:** Fees accumulated in TREASURY_SAFE (not deployer)

---

### Test 5: Emergency Pause Drill

- [ ] **COMPLIANCE_SAFE Triggers Pause**
  ```javascript
  const LaunchVault = await ethers.getContractAt("LaunchVault", "0x...");
  await LaunchVault.connect(COMPLIANCE_SAFE_SIGNER).pause();
  ```

- [ ] **Verify Contract Paused**
  ```javascript
  try {
    await LaunchVault.contribute({ value: ethers.parseEther("10") });
    console.log("❌ FAIL: Contribution succeeded (should be paused)");
  } catch (error) {
    console.log("✅ PASS: Contract paused successfully");
  }
  ```

- [ ] **GUARDIAN_EOA Unpauses (After Sign-Off)**
  ```javascript
  await LaunchVault.connect(GUARDIAN_SIGNER).unpause();
  ```

- [ ] **Verify Contract Resumed**
  ```javascript
  await LaunchVault.contribute({ value: ethers.parseEther("10") });
  console.log("✅ PASS: Contract resumed successfully");
  ```

- [ ] **Expected Result:** Pause/unpause works, operations blocked during pause

---

### Test 6: Sonny Transaction Preparation

- [ ] **Sonny Prepares Fee Change**
  - [ ] User asks: "Update RECMarketplace maker fee to 0.15%"
  - [ ] Sonny prepares transaction (does NOT sign)
  - [ ] Sonny displays transaction details for review

- [ ] **ADMIN_SAFE Signs**
  - [ ] OPS_SAFE owner 1 reviews and signs
  - [ ] OPS_SAFE owner 2 reviews and signs
  - [ ] Transaction executes (2-of-3 threshold met)

- [ ] **Events Service → Sonny Webhook**
  - [ ] Events Service detects transaction execution
  - [ ] Webhook fires to Sonny endpoint
  - [ ] Sonny logs audit trail
  - [ ] Sonny notifies user: "Fee updated to 0.15%"

- [ ] **Expected Result:** Sonny prepares (not executes), Safes sign, webhooks work

---

## 🌐 Phase 5: Website & Public Launch (Week 3-4)

### unykorn.org Homepage

- [ ] **Hero Section**
  - [ ] "Ask Sonny" button (opens chat widget)
  - [ ] "Talk to a Real Person" button → displays phone/email
  - [ ] Clean, minimal design (no clutter)

- [ ] **Contact Information Visible**
  - [ ] Phone: **(321) 806-7257**
  - [ ] Email: **kevan@unykorn.org**
  - [ ] Address: **6551 Peachtree Pkwy, Norcross, GA 30099**

- [ ] **Canonical Policy Published**
  - [ ] "Unykorn L1 (ChainId 7777) is the canonical registry"
  - [ ] "All tokenization and retirements occur on L1"
  - [ ] "Polygon/XRPL are optional liquidity surfaces"

- [ ] **SEO Structured Data**
  - [ ] Organization schema
  - [ ] LocalBusiness schema
  - [ ] FAQ schema
  - [ ] WebSite with SearchAction

---

### Sonny Chat Widget

- [ ] **Integration Live**
  - [ ] Sonny opens in sidebar/modal
  - [ ] Shows Safe balances (ADMIN, TREASURY, OPS)
  - [ ] Displays pending transactions count
  - [ ] Quick actions: "Check compliance", "Mint REC", "Retire carbon"

- [ ] **Sonny Knowledge Base**
  - [ ] Knows Unykorn L1 is canonical (7777)
  - [ ] Knows contact info (phone/email/address)
  - [ ] Knows RWA offerings (RECs, carbon, tax equity, T-REX)
  - [ ] Knows XRPL integration options (EVM sidechain vs native)
  - [ ] Can schedule calls, prepare transactions, check compliance

- [ ] **Human Escalation**
  - [ ] Large transactions → "Schedule a call"
  - [ ] Complex questions → "Talk to Legal" (email)
  - [ ] Urgent issues → Display phone number

---

## 📊 Phase 6: Monitoring & Operations (Ongoing)

### Service Level Objectives (SLOs)

- [ ] **Client Gateway P95 Latency < 300ms**
  - [ ] Dashboard configured (Grafana/Metabase)
  - [ ] Alert threshold: P95 > 500ms
  - [ ] Escalation: DevOps Lead → CTO

- [ ] **Event Index Lag < 2 Blocks**
  - [ ] Dashboard shows current lag
  - [ ] Alert threshold: Lag > 5 blocks
  - [ ] Escalation: DevOps Lead

- [ ] **Webhook Success Rate > 99%**
  - [ ] Dashboard shows delivery rate
  - [ ] Alert threshold: Success < 95%
  - [ ] Escalation: DevOps Lead → Product Manager

- [ ] **Pending Safe Queue Drain < 10 Minutes**
  - [ ] Dashboard shows queue depth
  - [ ] Alert threshold: Queue > 50 pending txs
  - [ ] Escalation: OPS_SAFE owners notified

---

### Change Control

- [ ] **All Role/Fee/Owner Changes Require:**
  - [ ] Sonny-generated summary (who, what, why)
  - [ ] Link to executed transaction (block explorer)
  - [ ] List of human signers (Safe owners)
  - [ ] Audit trail entry in CRM

- [ ] **Pre-Approval Required For:**
  - [ ] Contract upgrades (if UUPS)
  - [ ] Safe threshold changes
  - [ ] New Safe owner additions
  - [ ] Fee policy changes >10%

---

### Incident Response

- [ ] **Pause Policy Printed**
  - [ ] Who can pause: COMPLIANCE_SAFE, GUARDIAN_EOA
  - [ ] When to pause: Security incident, oracle failure, compliance breach
  - [ ] How to unpause: COMPLIANCE_SAFE + ADMIN_SAFE quorum

- [ ] **On-Call Grid Known**
  - [ ] Primary: DevOps Lead (phone/pager)
  - [ ] Secondary: CTO (phone/pager)
  - [ ] Compliance: Compliance Officer (phone/email)
  - [ ] Legal: Legal Counsel (email)

- [ ] **Unpause Requires:**
  - [ ] Root cause identified
  - [ ] Fix deployed/verified
  - [ ] COMPLIANCE_SAFE + ADMIN_SAFE sign-off
  - [ ] Incident report filed

---

## 🎯 Cutover Statement (Publish on Status Page)

**Effective Date:** _____________

### Official Policy

> **All tokenization, issuance, and retirement operations occur on Unykorn L1 (ChainId 7777).**
>
> Public chains (Polygon, XRPL EVM) are optional liquidity and interoperability surfaces. Unykorn L1 remains the canonical source of truth.
>
> Users can escalate to a human instantly via phone **(321) 806-7257** or email **kevan@unykorn.org**. Sonny AI is the default intake and transaction preparation layer.

### Supported Networks

- **Unykorn L1 (7777)**: Canonical registry, FREE GAS, full control
- **Polygon (137)**: Liquidity layer (DEX trading, USDC settlement)
- **XRPL EVM Sidechain**: XRPL ecosystem access (optional)
- **Ethereum (1)**: Insurance layer (Nexus Mutual $10M coverage)

### Contact

- **Address:** 6551 Peachtree Pkwy, Norcross, GA 30099
- **Phone:** (321) 806-7257
- **Email:** kevan@unykorn.org
- **Website:** https://unykorn.org

---

## ✅ Final Sign-Off

### Pre-Launch Approval (ALL Must Be Checked)

- [ ] All Phase 1-6 tasks completed
- [ ] All smoke tests passed
- [ ] All 4 Safes created with hardware wallet owners
- [ ] Deployer fully revoked (zero authority)
- [ ] Emergency pause tested successfully
- [ ] Sonny integration live (webhooks working)
- [ ] Website updated with canonical policy
- [ ] Monitoring dashboards live
- [ ] On-call rotation confirmed
- [ ] Legal/compliance sign-off obtained

### Authority Signatures

**Technical Lead:** _________________ Date: _______  
**CTO:** _________________ Date: _______  
**Compliance Officer:** _________________ Date: _______  
**Legal Counsel:** _________________ Date: _______  
**CEO/Founder:** _________________ Date: _______

---

## 🚀 GO-LIVE COMMAND

Once all signatures obtained:

```powershell
# 1. Final RPC check
.\scripts\unykorn.ps1 test-rpc

# 2. Final deployment verification
npx hardhat console --network unykorn
> // Verify all contracts, ownerships, roles

# 3. Update website (canonical policy live)
git push origin main  # Deploy to production

# 4. Announce on status page
# "Unykorn L1 is now LIVE and canonical"

# 5. Enable Sonny webhooks (production)
# POST /webhooks/safe/enable

# 🎉 LIVE!
```

---

**Unykorn L1 is the mothership. Safe is the control layer. Sonny is the front door.**

**Let's go live.** 🌟
