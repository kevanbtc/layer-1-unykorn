# Safe{Core} Integration on Unykorn L1 (ChainId 7777)

## Overview

This document outlines the complete Safe{Core} infrastructure deployment on Unykorn L1, enabling production-grade multisig custody, AI-assisted operations via Sonny, and seamless integration with your existing tokenization stack.

**Key Principle:** Sonny **prepares** transactions; Safes **sign** them. No hot keys, no unilateral spend, full audit trail.

---

## 🏗️ Infrastructure Components

### Safe{Core} Services on ChainId 7777

```
┌─────────────────────────────────────────────────┐
│ Safe Client Gateway (Public API)                │
│ • Single endpoint for Sonny + frontends         │
│ • Rate limit: 5 req/s (add caching layer)       │
│ • Behind your reverse proxy/CDN                 │
└─────────────────────────────────────────────────┘
           ▼
┌─────────────────────────────────────────────────┐
│ Safe Config Service                             │
│ • Registers chainId 7777                        │
│ • Points to your Tx Service instance            │
│ • Defines RPC, explorer, currency (UNYETH)      │
└─────────────────────────────────────────────────┘
           ▼
┌─────────────────────────────────────────────────┐
│ Safe Transaction Service                        │
│ • Indexes Safe activity on 7777                 │
│ • Event indexing (non-mainnet chain)            │
│ • Stores pending txs, signatures, state         │
└─────────────────────────────────────────────────┘
           ▼
┌─────────────────────────────────────────────────┐
│ Safe Events Service                             │
│ • Webhooks to Sonny on every change             │
│ • Role changes, ownership transfers, txs        │
│ • Pauses, fee updates, marketplace events       │
└─────────────────────────────────────────────────┘
```

---

## 🔐 The Four Control Points (Multisigs on 7777)

### ADMIN_SAFE (3-of-5 Threshold)

**Purpose:** Governance, DEFAULT_ADMIN_ROLE, protocol upgrades

**Signers:**
- Founder 1 (hardware wallet)
- Founder 2 (hardware wallet)
- Founder 3 (hardware wallet)
- Legal Counsel (hardware wallet)
- CTO (hardware wallet)

**Controls:**
- LicenseNFT ownership
- ComplianceRegistry admin role
- All AccessControl DEFAULT_ADMIN_ROLE grants
- Upgrade proposals (if using UUPS)

---

### TREASURY_SAFE (2-of-3 Threshold)

**Purpose:** Fees, royalties, redemptions, payouts

**Signers:**
- CFO (hardware wallet)
- Treasurer (hardware wallet)
- Founder 1 (hardware wallet)

**Controls:**
- RoyaltySplitter ownership
- FeeRouter ownership
- BufferPool ownership
- Fee recipient addresses (all contracts point here)
- Withdrawal operations

---

### COMPLIANCE_SAFE (2-of-3 Threshold)

**Purpose:** KYC/AML lists, freezes, transfer restrictions

**Signers:**
- Compliance Officer (hardware wallet)
- Legal Counsel (hardware wallet)
- External Auditor (hardware wallet)

**Controls:**
- ComplianceRegistry ownership
- ComplianceOracle ownership
- RetirementAttestation ownership
- PAUSER_ROLE (all pausable contracts)
- Allowlist/blocklist management
- Transfer restriction enforcement

---

### OPS_SAFE (2-of-3 Threshold)

**Purpose:** Markets, oracles, LaunchVault operations

**Signers:**
- CTO (hardware wallet)
- DevOps Lead (hardware wallet)
- Product Manager (hardware wallet)

**Controls:**
- LaunchVault ownership
- PriceOracle ownership
- WeatherOracle ownership
- RECMarketplace ownership
- ERC1155Carbon minting authority
- ERC1400TaxEquity minting authority
- Daily operational workflows

---

### GUARDIAN_EOA (1-of-1 Hardware Wallet)

**Purpose:** Emergency pause ONLY (kill switch)

**Signer:**
- Founder (Ledger/Trezor cold storage)

**Controls:**
- PAUSER_ROLE (global emergency pause)
- No spending authority
- No ownership transfers
- Used ONLY in crisis scenarios

---

## 🤖 Sonny (AI Front Door) - Capabilities

### What Sonny CAN Do

**Safe Lookup & Monitoring:**
- Query Safe balances (ETH, tokens, NFTs)
- Check owners, thresholds, pending transactions
- Read historical activity via Client Gateway

**Transaction Preparation (No Auto-Signing):**
- Build proposal drafts for common operations:
  - Role grants/revokes (AccessControl)
  - Ownership transfers (Ownable contracts)
  - Fee recipient updates
  - Pause/unpause operations
  - Marketplace listings
  - Mint/retire/burn flows (RECs, carbon, tax equity)
- Generate human-readable summaries
- Attach relevant compliance checks

**Compliance Integration:**
- Query ComplianceOracle before proposing transfers
- Check allowlists/blocklists
- Verify KYC/AML status
- Flag sanctioned addresses (OFAC)

**Workflow Orchestration:**
- Guide users through multi-step processes
- Schedule calls with humans: **(321) 806-7257**
- Email handoff: **kevan@unykorn.org**
- Generate proposal packs for CRM
- Create audit-ready documentation

**Real-Time Alerts (via Events Service Webhooks):**
- Ownership changed → notify + confirm
- Role granted/revoked → audit log + next action
- Fee updated → treasury notification
- Pause triggered → incident response checklist
- Large transfer → fraud check
- Marketplace listing → opportunity alert
- Retirement recorded → attestation confirmation

### What Sonny CANNOT Do

❌ Sign transactions (no private keys)  
❌ Unilaterally spend funds  
❌ Override Safe thresholds  
❌ Modify smart contracts directly  

**Guardrail:** Sonny **prepares**, Safes **approve**, blockchain **executes**.

---

## 📋 Ownership & Role Matrix (End State)

### Core Tokens

| Contract | Owner | Admin Role | Minter Role | Pauser Role |
|----------|-------|-----------|-------------|-------------|
| **UNYToken** | ADMIN_SAFE | ADMIN_SAFE | OPS_SAFE | COMPLIANCE_SAFE |
| **ComplianceRegistry** | COMPLIANCE_SAFE | COMPLIANCE_SAFE | - | COMPLIANCE_SAFE |
| **VaultProofNFT** | **LaunchVault** ✅ | ADMIN_SAFE | LaunchVault | - |
| **LaunchVault** | OPS_SAFE | ADMIN_SAFE | - | COMPLIANCE_SAFE |

### Licensing

| Contract | Owner | Fee Recipient | Pauser Role |
|----------|-------|--------------|-------------|
| **LicenseNFT** | ADMIN_SAFE | TREASURY_SAFE | COMPLIANCE_SAFE |
| **RoyaltySplitter** | TREASURY_SAFE | - | - |
| **FeeRouter** | TREASURY_SAFE | TREASURY_SAFE | - |

### Oracles

| Contract | Owner | ORACLE_ROLE | Pauser Role |
|----------|-------|------------|-------------|
| **PriceOracle** | OPS_SAFE | OPS_SAFE | COMPLIANCE_SAFE |
| **ComplianceOracle** | COMPLIANCE_SAFE | COMPLIANCE_SAFE | COMPLIANCE_SAFE |
| **WeatherOracle** | OPS_SAFE | OPS_SAFE | COMPLIANCE_SAFE |

### Advanced Tokens

| Contract | Owner | Admin Role | Minter Role | Pauser Role |
|----------|-------|-----------|-------------|-------------|
| **ERC1155Carbon** | ADMIN_SAFE | ADMIN_SAFE | OPS_SAFE | COMPLIANCE_SAFE |
| **ERC1400TaxEquity** | ADMIN_SAFE | ADMIN_SAFE | OPS_SAFE | COMPLIANCE_SAFE |
| **ERC3643Adapter** | ADMIN_SAFE | ADMIN_SAFE | OPS_SAFE | COMPLIANCE_SAFE |

### Retirement & Markets

| Contract | Owner | Admin Role | Fee Recipient | Pauser Role |
|----------|-------|-----------|--------------|-------------|
| **BufferPool** | TREASURY_SAFE | ADMIN_SAFE | TREASURY_SAFE | COMPLIANCE_SAFE |
| **RetirementAttestation** | COMPLIANCE_SAFE | COMPLIANCE_SAFE | - | COMPLIANCE_SAFE |
| **RECMarketplace** | OPS_SAFE | ADMIN_SAFE | TREASURY_SAFE | COMPLIANCE_SAFE |

### Emergency Powers

| Role | Holder | Scope |
|------|--------|-------|
| **PAUSER_ROLE** | COMPLIANCE_SAFE + GUARDIAN_EOA | All pausable contracts |
| **Emergency Pause** | GUARDIAN_EOA | Global kill switch (pause all) |

---

## 🚀 Deployment Checklist

### Phase 1: Safe Infrastructure (Week 1)

- [ ] Deploy Safe contracts to Unykorn L1 (7777)
  - [ ] Safe Singleton (core logic)
  - [ ] Safe Proxy Factory
  - [ ] Fallback Handler
  - [ ] MultiSend Library
- [ ] Verify contracts on L1 block explorer (Sourcify)
- [ ] Stand up Safe Transaction Service for chainId 7777
  - [ ] Configure RPC: `http://localhost:8545`
  - [ ] Event indexing enabled
  - [ ] Database schema created
- [ ] Stand up Safe Events Service
  - [ ] Configure webhook endpoints (Sonny/MCP)
  - [ ] Test event delivery
- [ ] Stand up Safe Config Service
  - [ ] Register chainId 7777
  - [ ] Set chain metadata (name: "Unykorn L1", currency: "UNYETH")
  - [ ] Point to Tx Service instance
- [ ] Stand up Safe Client Gateway
  - [ ] Behind reverse proxy (nginx/Caddy)
  - [ ] Rate limiting: 100 req/s (cache layer)
  - [ ] CORS configured for frontends
- [ ] Test end-to-end flow:
  - [ ] Create test Safe via UI/SDK
  - [ ] Submit tx → sign → execute
  - [ ] Verify Events Service webhook fires
  - [ ] Check Client Gateway returns correct data

---

### Phase 2: Create Production Safes (Week 1)

- [ ] Gather 5 hardware wallets for ADMIN_SAFE
- [ ] Gather 3 hardware wallets for TREASURY_SAFE
- [ ] Gather 3 hardware wallets for COMPLIANCE_SAFE
- [ ] Gather 3 hardware wallets for OPS_SAFE
- [ ] Prepare 1 cold-storage hardware wallet for GUARDIAN_EOA
- [ ] Deploy ADMIN_SAFE (3-of-5 threshold)
  - [ ] Add 5 owners
  - [ ] Test signature collection
  - [ ] Verify on-chain
- [ ] Deploy TREASURY_SAFE (2-of-3 threshold)
- [ ] Deploy COMPLIANCE_SAFE (2-of-3 threshold)
- [ ] Deploy OPS_SAFE (2-of-3 threshold)
- [ ] Record GUARDIAN_EOA address
- [ ] Add Safe addresses to `.env`:

```env
# === Gnosis Safes (Unykorn L1 - ChainId 7777) ===
ADMIN_SAFE=0x...
TREASURY_SAFE=0x...
COMPLIANCE_SAFE=0x...
OPS_SAFE=0x...
GUARDIAN_EOA=0x...
```

---

### Phase 3: Wire Ownerships & Roles (Week 2)

- [ ] Run ownership transfer script:
  ```powershell
  npm run wire:safes:unykorn
  ```
- [ ] Verify each transfer on-chain:
  - [ ] VaultProofNFT → LaunchVault ✅
  - [ ] ComplianceRegistry → COMPLIANCE_SAFE
  - [ ] LaunchVault → OPS_SAFE
  - [ ] RoyaltySplitter → TREASURY_SAFE
  - [ ] FeeRouter → TREASURY_SAFE
  - [ ] LicenseNFT → ADMIN_SAFE
  - [ ] All oracles → OPS_SAFE/COMPLIANCE_SAFE
  - [ ] All advanced tokens → ADMIN_SAFE
  - [ ] BufferPool → TREASURY_SAFE
  - [ ] RetirementAttestation → COMPLIANCE_SAFE
  - [ ] RECMarketplace → OPS_SAFE
- [ ] Grant AccessControl roles:
  - [ ] DEFAULT_ADMIN_ROLE → ADMIN_SAFE (all contracts)
  - [ ] MINTER_ROLE → OPS_SAFE (tokens)
  - [ ] PAUSER_ROLE → COMPLIANCE_SAFE + GUARDIAN_EOA
  - [ ] ORACLE_ROLE → OPS_SAFE/COMPLIANCE_SAFE
- [ ] Point all fee recipients → TREASURY_SAFE
- [ ] **CRITICAL:** Revoke deployer from all roles
  - [ ] Verify deployer has NO admin roles
  - [ ] Verify deployer has NO ownership
  - [ ] Verify deployer cannot pause
- [ ] Test emergency pause:
  - [ ] GUARDIAN_EOA pauses LaunchVault
  - [ ] Verify contributions blocked
  - [ ] COMPLIANCE_SAFE unpauses
  - [ ] Verify contributions resume

---

### Phase 4: Sonny Integration (Week 2)

- [ ] Deploy Sonny MCP server
- [ ] Configure Safe{Core} Protocol Kit:
  ```typescript
  const protocolKit = await Safe.init({
    provider: 'http://localhost:8545',
    chainId: 7777,
    signer: SONNY_WALLET_ADDRESS, // Read-only, no spend authority
  });
  ```
- [ ] Add Safe tools to Sonny (LangChain):
  - [ ] `getSafeBalance` - Query ETH/token balances
  - [ ] `getSafeOwners` - Read owners + threshold
  - [ ] `getPendingTransactions` - List queued txs
  - [ ] `prepareRoleGrant` - Draft role grant tx
  - [ ] `prepareOwnershipTransfer` - Draft ownership transfer
  - [ ] `prepareFeeUpdate` - Draft fee recipient change
  - [ ] `preparePause` - Draft pause tx
  - [ ] `prepareMint` - Draft token/NFT mint
  - [ ] `prepareRetirement` - Draft retirement attestation
- [ ] Configure Events Service webhooks:
  - [ ] POST `/sonny/webhooks/safe-events`
  - [ ] Event types: ownership, roles, txs, pauses, fees
  - [ ] Sonny processes → logs audit trail → notifies users
- [ ] Test Sonny workflows:
  - [ ] User: "Check ADMIN_SAFE balance"
  - [ ] User: "Prepare a role grant for OPS_SAFE"
  - [ ] User: "Show me pending transactions"
  - [ ] User: "Deploy a new Safe for project X"
- [ ] Add human handoff triggers:
  - [ ] Large value txs → schedule call
  - [ ] Complex compliance questions → email Legal
  - [ ] Urgent issues → display phone: **(321) 806-7257**

---

### Phase 5: Frontend Integration (Week 3)

- [ ] Update unykorn.org homepage:
  - [ ] Hero: "Ask Sonny" (chat opens)
  - [ ] CTA #1: "Talk to a Real Person" → **(321) 806-7257**
  - [ ] CTA #2: "Schedule a Call" → Calendly/HubSpot
  - [ ] Address visible: **6551 Peachtree Pkwy, Norcross, GA 30099**
- [ ] Sonny chat widget:
  - [ ] Opens in sidebar/modal
  - [ ] Shows Safe balances (ADMIN, TREASURY, OPS)
  - [ ] Displays pending txs count
  - [ ] Quick actions: "Check compliance", "Mint REC", "Retire carbon"
- [ ] Safe App integration (optional):
  - [ ] Build custom Safe App for Unykorn flows
  - [ ] Embed in Safe{Wallet} UI
  - [ ] Users can execute Unykorn txs directly from Safe interface

---

### Phase 6: Smoke Tests (Week 3)

- [ ] **Test 1: Contribution Flow**
  - [ ] User contributes 10 UNYETH to LaunchVault
  - [ ] VaultProofNFT automatically minted (LaunchVault owner)
  - [ ] Events Service fires webhook
  - [ ] Sonny confirms: "NFT #X minted to user Y"
- [ ] **Test 2: Fee Update**
  - [ ] OPS_SAFE prepares fee update tx (RECMarketplace)
  - [ ] 2-of-3 signatures collected
  - [ ] Tx executes
  - [ ] Events Service webhook → Sonny logs audit trail
- [ ] **Test 3: Emergency Pause**
  - [ ] GUARDIAN_EOA triggers global pause
  - [ ] All pausable contracts frozen
  - [ ] Sonny alerts all stakeholders
  - [ ] COMPLIANCE_SAFE unpauses after review
- [ ] **Test 4: REC Lifecycle**
  - [ ] Mint REC (OPS_SAFE signs)
  - [ ] List on RECMarketplace (user tx)
  - [ ] Buy REC (buyer tx)
  - [ ] Retire REC (user tx)
  - [ ] RetirementAttestation recorded (COMPLIANCE_SAFE verifies)
  - [ ] Sonny confirms each step via webhooks
- [ ] **Test 5: Carbon Credit Bridge** (when ready)
  - [ ] Lock ERC1155Carbon on L1 (CarbonVault)
  - [ ] LayerZero message → Polygon
  - [ ] Mint wrapped wUNY-Carbon on Polygon
  - [ ] Trade on Polygon DEX
  - [ ] Burn on Polygon → unlock on L1
  - [ ] Retire on L1 (RetirementAttestation)

---

## 🌉 XRPL Compatibility (Multi-Chain Strategy)

### XRPL Classic (Non-EVM)

**Safe does NOT run on XRPL classic.**

**Alternative:**
- Use **XRPL native multisign** for custody
- Use **trustlines** for fungible tokens
- Use **XLS-20 NFTs** for non-fungibles
- Sonny can orchestrate XRPL flows, but NOT via Safe

**When to use:**
- Direct XRPL ecosystem integration
- Lower transaction fees (~$0.00001)
- XRPL-native DeFi (AMM, orderbooks)

---

### XRPL EVM Sidechain (EVM-Compatible)

**Safe DOES run on XRPL EVM Sidechain.**

**Integration:**
1. Deploy minimal Safe footprint on XRPL EVM:
   - Mirror TREASURY_SAFE (for XRPL liquidity)
   - Mirror OPS_SAFE (for XRPL operations)
2. Use **XRPL EVM Bridge** to move assets:
   - Lock assets on Unykorn L1
   - Mint wrapped assets on XRPL EVM
   - Trade on XRPL EVM DEXs
   - Burn wrapped → unlock on L1
3. Sonny treats XRPL EVM as "another EVM network":
   - Same Safe SDK
   - Same transaction preparation flows
   - Same webhook integration

**When to use:**
- Reach XRPL users who prefer EVM UX
- Access XRPL EVM liquidity pools
- Bridge between L1 and XRPL ecosystem

**Cost comparison:**
- Unykorn L1: **FREE GAS**
- XRPL EVM: ~$0.001 per tx
- XRPL Classic: ~$0.00001 per tx

---

## 📊 Monitoring & Observability

### Dashboards (Grafana/Metabase)

**Safe Metrics:**
- Total Safes created on 7777
- Total value locked (TVL) in Safes
- Pending transactions count
- Average signature collection time
- Failed transaction rate

**Contract Metrics:**
- LaunchVault contributions (24h/7d/30d)
- VaultProofNFT mint count
- REC marketplace volume
- Carbon retirement count
- Tax equity token issuance

**Infrastructure Metrics:**
- Transaction Service indexing lag
- Events Service webhook success rate
- Client Gateway cache hit rate
- API rate limit breaches

---

### Alerts (PagerDuty/Slack)

**Critical:**
- Emergency pause triggered (GUARDIAN_EOA)
- Ownership transfer executed
- Admin role granted/revoked
- Large value transfer (>$10K)
- Compliance violation detected

**Warning:**
- Safe threshold changed
- Fee recipient updated
- Oracle feed stale (>1 hour)
- Webhook delivery failed (>3 retries)
- API rate limit hit

**Info:**
- New Safe created
- Contribution received
- Marketplace listing created
- Retirement recorded

---

## 🛡️ Security Best Practices

### Least Privilege

✅ Each Safe controls ONLY what it needs  
✅ No Safe has global admin powers  
✅ Deployer has ZERO authority after migration  
✅ GUARDIAN_EOA can ONLY pause (no spending)  

### Timelock (If Upgradable)

If using UUPS upgradable contracts:
- Add 48-72 hour Timelock
- ADMIN_SAFE proposes upgrade
- Timelock enforces delay
- COMPLIANCE_SAFE can veto during delay
- Emergency fast-track requires ADMIN_SAFE + COMPLIANCE_SAFE quorum

### Secrets Management

✅ Sonny has NO private keys  
✅ Sonny cannot sign transactions  
✅ All spending requires Safe threshold  
✅ Hardware wallets for all Safe owners  
✅ Cold storage for GUARDIAN_EOA  

### Audit Trail

✅ All Safe transactions logged on-chain  
✅ Events Service webhooks to Sonny  
✅ Sonny generates human-readable summaries  
✅ CRM integration for compliance records  
✅ Quarterly audit reports (Trail of Bits)  

---

## 📞 Human Escalation Paths

### When Sonny Hands Off to Humans

**Scenarios:**
- Complex legal/compliance questions
- Large value transactions (>$100K)
- Emergency situations
- Contract upgrades
- New Safe creation for external partners
- Policy changes

**Contact Methods:**
1. **Phone:** **(321) 806-7257** (business hours)
2. **Email:** **kevan@unykorn.org** (24-48 hour response)
3. **Physical:** **6551 Peachtree Pkwy, Norcross, GA 30099**
4. **Emergency:** GUARDIAN_EOA pauses contracts, calls Compliance Officer

---

## 📚 Documentation & Training

### For Developers

- **Safe{Core} SDK Docs:** https://docs.safe.global/core-sdk
- **Protocol Kit Reference:** Integration examples
- **API Kit Reference:** Transaction Service API
- **LangChain Integration:** Sonny tool development

### For Operations Team

- **Safe Owner Handbook:** How to sign transactions
- **Emergency Procedures:** When to trigger pause
- **Compliance Playbook:** KYC/AML workflows
- **Fee Management Guide:** Treasury operations

### For External Partners

- **Safe on Unykorn 7777:** One-page overview
- **Multi-Chain Strategy:** L1 + Polygon + XRPL
- **Audit Reports:** Trail of Bits findings
- **Insurance Coverage:** Nexus Mutual details

---

## 🎯 Success Criteria

### Week 1 (Infrastructure)

✅ All Safe services running on 7777  
✅ Client Gateway responding <100ms  
✅ Events Service webhooks 99.9% delivery  

### Week 2 (Control Transfer)

✅ All 4 Safes created with hardware owners  
✅ All contracts owned by Safes (deployer revoked)  
✅ Emergency pause tested successfully  

### Week 3 (AI Integration)

✅ Sonny can read all Safe data  
✅ Sonny can prepare 10+ transaction types  
✅ Webhook alerts working (100% delivery)  

### Week 4 (Production Launch)

✅ First real contribution → NFT mint  
✅ First REC minted → listed → retired  
✅ Zero security incidents  
✅ 95% uptime on all services  

---

## 💰 Cost Estimates

| Item | Setup Cost | Annual Cost |
|------|-----------|-------------|
| **Safe Infrastructure** | $0 (open-source) | $0 (self-hosted) |
| **Hardware Wallets** | $500 (5 Ledgers) | $0 |
| **Server Hosting** | $100 | $1,200 |
| **Sonny Development** | $5,000 | $0 |
| **Security Audit** | $100,000 | $25,000 |
| **Nexus Mutual Insurance** | $0 | $250,000 |
| **TOTAL** | **$105,600** | **$276,200** |

**Note:** Unykorn L1 gas = **FREE FOREVER** 🎉

---

## 🚀 Next Steps

1. **Start L1 nodes:** `.\scripts\unykorn.ps1 start`
2. **Deploy Safe contracts:** Follow Safe deployment guide
3. **Stand up Safe services:** Transaction, Events, Config, Client Gateway
4. **Create 4 Safes:** ADMIN, TREASURY, COMPLIANCE, OPS + GUARDIAN
5. **Wire ownerships:** `npm run wire:safes:unykorn`
6. **Integrate Sonny:** Add Safe tools + webhook handlers
7. **Smoke test:** Run all 5 test scenarios
8. **Launch:** Update unykorn.org with Sonny chat

---

**Safe{Core} + Sonny + Unykorn L1 = Production-grade RWA infrastructure with AI-first UX.** 🌟

**Your L1 is the mothership. Safe is the control layer. Sonny is the front door.**
