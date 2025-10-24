# 🚀 DEPLOYMENT STATUS - READY TO LAUNCH

## ✅ INFRASTRUCTURE: 100% READY

**What's Done:**
- ✅ 4 Core Contracts (UNY, NFT, Registry, Vault)
- ✅ 7 UNY-ID Energy Contracts (Identity + Compliance + MRV + Tokens + Retirement)
- ✅ 5 Deployment Scripts (preflight, deploy, verify, snapshot, uny-id)
- ✅ Hardhat Config (Solidity 0.8.24, optimizer runs: 2000)
- ✅ Complete Documentation (3 guides: Deployment, Emergency, UNY-ID)

**What You Need to Do:**
1. ⚠️ Configure `.env` with your keys (2 minutes)
2. ⚠️ Fund deployer with 0.5+ MATIC (2 minutes)
3. ⚠️ Run pre-flight check (30 seconds)

---

## 🎬 LAUNCH SEQUENCE (After Pre-Flight Passes)

### OPTION A: Deploy Basic Token System (Tonight)
```bash
npm run deploy:polygon      # 5 mins - deploys UNY + NFT + Registry + Vault
npm run verify:polygon      # 10 mins - verifies on Polygonscan
npm run snapshot:polygon    # 1 min - captures on-chain state
```

**What you get:**
- UNY Token (ERC-20) - 100M supply
- VaultProof NFT (ERC-721) - Soulbound
- ComplianceRegistry - Transfer gates
- LaunchVault - Mint + payment

---

### OPTION B: Deploy Full UNY-ID Energy & RWA System
```bash
npm run deploy:unyid:polygon    # 7 mins - deploys 7-contract identity system
npm run verify:polygon          # 15 mins - verifies all contracts
npm run snapshot:polygon        # 1 min - captures state
```

**What you get:**
- Complete identity/compliance infrastructure
- W3C DID standard + verifiable credentials
- MRV (Measurement, Reporting, Verification) oracle
- Energy certificates (RECs/EACs) with serial tracking
- Regulated securities (ERC-1400 partitions)
- Anti-double-count retirement system
- Registry bridges (Verra, Gold Standard, I-REC)

**Full Details:** See `UNY_ID_QUICKSTART.md`

---

## ⚙️ STEP 1: Configure .env (2 minutes)

Edit `.env` file with these values:

```bash
# Polygon RPC (use any Polygon mainnet RPC)
POLYGON_RPC=https://polygon-rpc.com

# Your deployer private key (64 hex chars, starts with 0x)
DEPLOYER_PK=0xYOUR_PRIVATE_KEY_HERE

# Get API key at: https://polygonscan.com/myapikey
POLYGONSCAN_API_KEY=YOUR_API_KEY_HERE
```

**How to get your private key:**
- MetaMask: Settings → Security & Privacy → Show Private Key
- **⚠️ NEVER commit .env to git!** (already in .gitignore)

---

## 💰 STEP 2: Fund Deployer (2 minutes)

1. Run preflight to see your deployer address:
   ```bash
   npm run preflight
   ```

2. Send **0.5+ MATIC** to that address (1.0 MATIC recommended for retries)

3. Verify balance:
   ```bash
   npm run preflight
   ```

---

## ✈️ STEP 3: Run Pre-Flight Check

```bash
npm run preflight
```

**What it checks:**
- ✅ Environment variables configured
- ✅ Polygon RPC connection (chainId 137)
- ✅ Deployer balance (≥ 0.5 MATIC)
- ✅ Contract files exist
- ✅ Hardhat config correct (0.8.24, runs: 2000)
- ✅ Dependencies installed

**Expected output:**
```
🎉 ALL CHECKS PASSED - READY FOR DEPLOYMENT!

DEPLOYMENT SEQUENCE:
   1. npm run deploy:polygon      (~5 mins)
   2. npm run verify:polygon      (~10 mins)
   3. npm run snapshot:polygon    (~1 min)

✅ Run: npm run deploy:polygon
```

**If errors:** Fix them, then re-run `npm run preflight`

---

## 🚀 STEP 4: Deploy (5 minutes)

```bash
npm run deploy:polygon
```

**What happens:**
1. Compiles contracts
2. Deploys 4 contracts in sequence
3. Transfers NFT ownership to LaunchVault
4. Saves deployment record to `deployments/polygon-YYYYMMDD.json`
5. Prints canonical addresses + verification commands

**⚠️ CRITICAL:** Save all 4 contract addresses immediately!

---

## 🔍 STEP 5: Verify (10 minutes)

```bash
npm run verify:polygon
```

**What happens:**
- Submits source code to Polygonscan
- Verifies constructor arguments
- Shows green ✓ checkmark on scanner

**If "Already Verified":** Great! You're done.

**If rate limited:** Wait 30 seconds, retry.

---

## 📸 STEP 6: Snapshot (1 minute)

```bash
npm run snapshot:polygon
```

**What happens:**
- Captures on-chain state at current block
- Records total supply, ownership, balances
- Saves to `snapshots/polygon-XXXXXXXX.json`
- Creates forensic audit trail

---

## ✅ POST-DEPLOYMENT CHECKLIST

### Immediate (5 minutes)
- [ ] All contracts verified on Polygonscan (green checkmarks)
- [ ] Constructor args decoded correctly
- [ ] Git tag: `git tag -a v1.0.0-mainnet -m "Polygon launch" && git push --tags`
- [ ] Backup `deployments/*.json` to secure location

### Within 1 Hour
- [ ] Update README.md with canonical addresses
- [ ] Test mint via Polygonscan "Write Contract" tab
- [ ] Verify NFT shows on OpenSea

### Within 24 Hours
- [ ] Seed liquidity on QuickSwap (UNY/USDC pool)
- [ ] Deploy frontend with contract addresses
- [ ] Set up monitoring (Tenderly/Defender)

---

## 📚 DOCUMENTATION

| File | Purpose |
|------|---------|
| **DEPLOYMENT_GUIDE.md** | Complete 25-minute deployment plan with troubleshooting |
| **EMERGENCY_FIXES.md** | Quick fixes for common errors (keep open during deploy!) |
| **UNY_ID_QUICKSTART.md** | Energy & RWA passport system guide (7 contracts) |
| **docs/UNY_ID_SYSTEM.md** | Complete architecture guide (1,200+ lines) |

---

## 🆘 TROUBLESHOOTING

**"Insufficient funds"**  
→ Fund deployer with 0.5+ MATIC, retry

**"Bytecode doesn't match"**  
→ Check hardhat.config.js has 0.8.24 + runs: 2000

**"Rate limited"**  
→ Wait 30 seconds, retry verify

**"Network does not support ENS"**  
→ Check POLYGON_RPC in .env

**More issues?** → See `EMERGENCY_FIXES.md`

---

## 🎯 YOUR NEXT COMMAND

```bash
code .env
```

**Then add your:**
1. POLYGON_RPC (e.g., https://polygon-rpc.com)
2. DEPLOYER_PK (0x + 64 hex chars)
3. POLYGONSCAN_API_KEY (from https://polygonscan.com/myapikey)

**After that:**
```bash
npm run preflight
```

---

## 🎉 YOU'RE 3 STEPS FROM MAINNET!

1. Configure `.env` (2 mins)
2. Fund deployer (2 mins)
3. Run `npm run preflight` (30 secs)

**Then fire:** `npm run deploy:polygon`

**Total time:** 6 minutes → live on Polygon mainnet 🚀

---

**Last Updated:** October 24, 2025  
**Status:** Production-Ready ✅  
**Action Required:** Configure `.env` file
