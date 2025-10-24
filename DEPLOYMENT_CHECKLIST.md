# 🚀 Polygon Mainnet Deployment Checklist

**Date**: ___________________  
**Deployer**: ___________________  
**Network**: Polygon (137)

---

## ✅ Pre-Deployment (Complete BEFORE deploying)

### Environment Setup
- [ ] Node.js 18+ installed (`node --version`)
- [ ] Dependencies installed (`npm install`)
- [ ] Hardhat verify plugin installed (`npm i -D @nomicfoundation/hardhat-verify`)
- [ ] `.env` file created from `.env.example`
- [ ] All environment variables configured:
  - [ ] `POLYGON_RPC` set
  - [ ] `DEPLOYER_PK` set (with 0x prefix)
  - [ ] `POLYGONSCAN_API_KEY` set
  - [ ] `TREASURY_ADDRESS` set

### Funding
- [ ] Deployer account has **0.1+ MATIC** (check on Polygonscan)
- [ ] LP wallet has **USDC** for initial liquidity (if seeding pool)

### Security
- [ ] Private key is from a secure source (hardware wallet or secure generation)
- [ ] Private key is NOT used for any other purpose
- [ ] `.env` file is in `.gitignore` (verify: `git check-ignore .env`)
- [ ] Treasury address is a **multisig** (recommended) or secure EOA

### Testing
- [ ] Contracts compile without errors (`npm run compile`)
- [ ] RPC connection tested (`.\scripts\test-rpc-suite.ps1 -RpcUrl "https://polygon-rpc.com"`)
- [ ] Chain ID confirmed as `0x89` (137 in decimal)

---

## 🚀 Deployment (Execute in order)

### Step 1: Final Compilation
- [ ] `npm run compile` - no errors
- [ ] Review `hardhat.config.js` network settings
- [ ] Double-check `.env` values

### Step 2: Deploy Contracts
- [ ] Run: `npm run deploy:polygon`
- [ ] **Wait for completion** (~2-3 minutes)
- [ ] Screenshot/save console output
- [ ] Verify all 4 contracts deployed:
  - [ ] UNY Token address: _______________________
  - [ ] VaultProofNFT address: _______________________
  - [ ] ComplianceRegistry address: _______________________
  - [ ] LaunchVault address: _______________________

### Step 3: Save Deployment Record
- [ ] Deployment JSON created in `deployments/polygon-YYYYMMDD.json`
- [ ] JSON file contains all constructor args
- [ ] Git commit hash captured
- [ ] **Backup this file immediately** (Google Drive, USB, etc.)

---

## 🔍 Verification (Do within 1 hour of deployment)

### Step 4: Verify on Polygonscan
- [ ] Run: `npm run verify:polygon`
- [ ] OR verify manually (see POLYGON_DEPLOYMENT.md)
- [ ] Check each contract on Polygonscan:
  - [ ] UNY: `https://polygonscan.com/address/0xYOUR_ADDRESS#code` ✅ verified
  - [ ] NFT: `https://polygonscan.com/address/0xYOUR_ADDRESS#code` ✅ verified
  - [ ] Registry: `https://polygonscan.com/address/0xYOUR_ADDRESS#code` ✅ verified
  - [ ] LaunchVault: `https://polygonscan.com/address/0xYOUR_ADDRESS#code` ✅ verified

---

## 🎨 NFT Setup (Within 24 hours)

### Step 5: Prepare Metadata
- [ ] Create `metadata/1.json` with:
  - [ ] Name
  - [ ] Description
  - [ ] Image URL (ipfs://)
  - [ ] Attributes
- [ ] Upload image to IPFS (Pinata or web3.storage)
- [ ] Upload metadata JSON to IPFS
- [ ] Test IPFS URL loads: `https://ipfs.io/ipfs/YOUR_CID`

### Step 6: Test Mint
- [ ] Open Hardhat console: `npx hardhat console --network polygon`
- [ ] Get LaunchVault contract
- [ ] Mint test NFT with IPFS URI
- [ ] Verify NFT minted (totalSupply = 1)
- [ ] Check owner is correct address

### Step 7: OpenSea Verification
- [ ] Wait 2-3 minutes for indexing
- [ ] Visit: `https://opensea.io/assets/matic/0xNFT_ADDRESS/1`
- [ ] Verify image displays correctly
- [ ] Verify metadata is correct
- [ ] Refresh metadata if needed

---

## 💧 Liquidity (Within 48 hours)

### Step 8: Mint UNY for LP
- [ ] Open Hardhat console
- [ ] Mint UNY to LP wallet (e.g., 2.5M tokens)
- [ ] Verify balance on Polygonscan
- [ ] Transfer USDC to LP wallet (for pairing)

### Step 9: Create QuickSwap Pool
- [ ] Go to: https://quickswap.exchange/#/add
- [ ] Select: UNY (paste address) + USDC
- [ ] Choose fee tier: **0.3%**
- [ ] Set initial price (e.g., 1 UNY = $0.10)
- [ ] Add liquidity:
  - [ ] Amount UNY: _______________________
  - [ ] Amount USDC: _______________________
- [ ] Confirm transaction
- [ ] Save LP token address: _______________________
- [ ] Save QuickSwap pair URL: _______________________

---

## 📸 State Snapshot (Immediately after setup)

### Step 10: Capture Blockchain State
- [ ] Run: `npm run snapshot:polygon`
- [ ] Verify snapshot created in `snapshots/` directory
- [ ] Review snapshot data:
  - [ ] UNY total supply correct
  - [ ] NFT total supply = 1
  - [ ] Mint price = 0.01 MATIC
  - [ ] LaunchVault balance shown
- [ ] **Backup snapshot file**
- [ ] Commit to git: `git add snapshots/`

---

## 📝 Documentation (Same day)

### Step 11: Update README.md
- [ ] Add "Canonical Addresses" section (template in POLYGON_DEPLOYMENT.md)
- [ ] Include all 4 contract addresses
- [ ] Add Polygonscan links
- [ ] Add OpenSea collection link
- [ ] Add QuickSwap pair link
- [ ] Update deployment date

### Step 12: Git Tagging
- [ ] Commit deployment files:
  ```bash
  git add deployments/ snapshots/ README.md
  git commit -m "Polygon mainnet launch: UNY/NFT/Registry/LaunchVault"
  ```
- [ ] Tag release:
  ```bash
  git tag -a v1.0.0 -m "Mainnet launch (Polygon) - October 24, 2025"
  ```
- [ ] Push to GitHub:
  ```bash
  git push origin main
  git push --tags
  ```

---

## 🔒 Security & Ownership (Within 1 week)

### Step 13: Transfer Ownership (Optional but Recommended)
- [ ] **Option A**: Transfer to multisig
  - [ ] LaunchVault → Gnosis Safe address: _______________________
  - [ ] UNY Token → Gnosis Safe address: _______________________
- [ ] **Option B**: Renounce ownership (IRREVERSIBLE!)
  - [ ] Only if fully decentralized model intended
  - [ ] Cannot mint more UNY tokens after renouncing
  - [ ] Cannot pause contracts after renouncing

### Step 14: Security Audit (If Budget Allows)
- [ ] Trail of Bits quote requested: $__________
- [ ] OpenZeppelin quote requested: $__________
- [ ] Audit timeline: __________ weeks
- [ ] OR: Self-audit checklist completed (see PRODUCTION_SECURITY.md)

---

## 📊 Monitoring (Setup immediately)

### Step 15: Set Up Alerts
- [ ] **Tenderly** monitoring:
  - [ ] Add UNY contract
  - [ ] Add NFT contract
  - [ ] Add LaunchVault contract
  - [ ] Enable failed transaction alerts
  - [ ] Enable ownership change alerts
- [ ] **DeBank** watch list:
  - [ ] Add all contract addresses
  - [ ] Track holder count
  - [ ] Track liquidity
- [ ] **Discord/Slack webhook** for critical events (optional)

---

## 📢 Public Announcement (After everything above is complete)

### Step 16: Prepare Announcement
- [ ] Draft Twitter/X post with:
  - [ ] Contract addresses
  - [ ] OpenSea link
  - [ ] QuickSwap link
  - [ ] Mint instructions
  - [ ] Launch graphic/GIF
- [ ] Draft Discord/Telegram announcement
- [ ] Prepare website banner (if applicable)

### Step 17: Go Live
- [ ] Post on Twitter/X
- [ ] Post in Discord
- [ ] Post in Telegram
- [ ] Update website (if applicable)
- [ ] Email newsletter (if applicable)

---

## ✅ FINAL CHECKLIST

**All must be checked before considering deployment "complete":**

- [ ] All 4 contracts deployed successfully
- [ ] All contracts verified on Polygonscan (green checkmarks)
- [ ] NFT metadata pinned to IPFS and displaying correctly
- [ ] At least 1 test NFT minted successfully
- [ ] OpenSea collection visible and correct
- [ ] QuickSwap liquidity pool created and trading
- [ ] State snapshot captured and backed up
- [ ] Deployment JSON backed up (3 locations: repo + cloud + local)
- [ ] README.md updated with canonical addresses
- [ ] Git tagged with v1.0.0
- [ ] Monitoring/alerts set up
- [ ] Public announcement posted
- [ ] Team briefed on support procedures

---

## 📞 Emergency Contacts

**Deployment Lead**: _______________________  
**Security Lead**: _______________________  
**DevOps**: _______________________

---

## 🎉 Deployment Complete!

**Date/Time**: _______________________  
**Total Duration**: _______________________  
**Total Gas Spent**: _______________________ MATIC  
**NFTs Minted**: _______________________  
**Initial Liquidity**: _______________________ UNY + _______________________ USDC

**Signature**: _______________________

---

**Keep this checklist for audit trail. Archive with deployment artifacts.**
