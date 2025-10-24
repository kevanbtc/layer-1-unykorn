# 🔐 Creating Multiple Business Safes

You already have one Safe: `0x1f0f32c1b4f84230F38F1DEf776b96b83fa60e9A`

Now let's create **4 specialized Safes** for professional business operations.

---

## Your 4 Production Safes

| Safe | Threshold | Owners | Purpose |
|------|-----------|--------|---------|
| **ADMIN_SAFE** | 3-of-5 | Founder1, Founder2, Founder3, Legal, CTO | Governance, protocol upgrades, admin roles |
| **TREASURY_SAFE** | 2-of-3 | CFO, Treasurer, Founder1 | Fees, royalties, withdrawals |
| **COMPLIANCE_SAFE** | 2-of-3 | Compliance Officer, Legal, Auditor | KYC/AML, freezes, pauses |
| **OPS_SAFE** | 2-of-3 | CTO, DevOps Lead, Product Mgr | Markets, oracles, daily operations |

Plus **GUARDIAN_EOA** (1 hardware wallet, emergency pause only)

---

## Step 1: Prepare Hardware Wallet Addresses

**IMPORTANT:** Replace the placeholder addresses in `.env` with **real hardware wallet addresses**.

Open `.env` and update these lines:

```env
# Replace ALL of these with actual Ledger/Trezor addresses
FOUNDER_1=0x...  # Your primary Ledger
FOUNDER_2=0x...  # Co-founder's Ledger
FOUNDER_3=0x...  # Third founder's Ledger
LEGAL_COUNSEL=0x...
CTO=0x...
CFO=0x...
TREASURER=0x...
COMPLIANCE_OFFICER=0x...
EXTERNAL_AUDITOR=0x...
DEVOPS_LEAD=0x...
PRODUCT_MANAGER=0x...
GUARDIAN_EOA=0x...  # Cold storage Ledger (offline backup)
```

**Tip:** Connect each hardware wallet to MetaMask, get the address, then disconnect and store securely.

---

## Step 2: Deploy Safes on Unykorn L1 (FREE GAS!)

```powershell
# Make sure your L1 node is running
.\scripts\unykorn.ps1 besu-up

# Create all 4 Safes + GUARDIAN
npm run create:safes:unykorn
```

**Expected output:**
- ✅ ADMIN_SAFE deployed at `0x...`
- ✅ TREASURY_SAFE deployed at `0x...`
- ✅ COMPLIANCE_SAFE deployed at `0x...`
- ✅ OPS_SAFE deployed at `0x...`
- ✅ GUARDIAN_EOA recorded: `0x...`
- ✅ Saved to `deployments/safes-7777.json`
- **Cost: $0.00** (FREE GAS!)

---

## Step 3: Update .env with Safe Addresses

The script will output something like:

```
ADMIN_SAFE=0xAbC123...
TREASURY_SAFE=0xDeF456...
COMPLIANCE_SAFE=0x789GhI...
OPS_SAFE=0xJkL012...
GUARDIAN_EOA=0xMnO345...
```

Copy these lines and **uncomment/update** them in `.env`:

```env
# === Gnosis Safes ===
ADMIN_SAFE=0xAbC123...        # 3-of-5: Governance
TREASURY_SAFE=0xDeF456...     # 2-of-3: Fees
COMPLIANCE_SAFE=0x789GhI...   # 2-of-3: Pauses
OPS_SAFE=0xJkL012...          # 2-of-3: Operations
GUARDIAN_EOA=0xMnO345...      # 1-of-1: Emergency
```

---

## Step 4: Test Safe Operations

Connect to your L1 and verify each Safe:

```powershell
npx hardhat console --network unykorn
```

```javascript
// Check ADMIN_SAFE owners and threshold
const Safe = await ethers.getContractAt(
  "IGnosisSafe",
  process.env.ADMIN_SAFE
);

await Safe.getOwners();  // Should return 5 addresses
await Safe.getThreshold();  // Should return 3
```

---

## Step 5: Deploy Contracts & Wire Ownerships

```powershell
# Deploy all 16 contracts to Unykorn L1
npm run deploy:energy:unykorn

# Transfer ownerships to Safes (revoke deployer)
npm run wire:safes:unykorn
```

**Result:**
- VaultProofNFT → owned by LaunchVault
- ComplianceRegistry → owned by COMPLIANCE_SAFE
- LaunchVault → owned by OPS_SAFE
- FeeRouter → recipient = TREASURY_SAFE
- All admin roles → ADMIN_SAFE
- All pauser roles → COMPLIANCE_SAFE + GUARDIAN_EOA
- **Deployer has ZERO authority** ✅

---

## Alternative: Create Safes on Polygon (For Testing)

```powershell
# Same process, different network
npm run create:safes:polygon

# Cost: ~0.40 MATIC (~$0.20 for 4 Safes)
```

---

## Adding Owners Later (After Deployment)

If you deployed with placeholder addresses, you can add/remove owners:

```javascript
// Example: Replace deployer with real hardware wallet
const Safe = await ethers.getContractAt("IGnosisSafe", ADMIN_SAFE_ADDRESS);

// Propose transaction to add new owner
const tx = await Safe.populateTransaction.addOwnerWithThreshold(
  "0xNEW_HARDWARE_WALLET",  // New owner
  3  // Keep threshold at 3
);

// Sign with existing owners (3-of-5)
// Execute via Safe{Wallet} UI or SDK
```

---

## Managing Multiple Safes

### Method 1: Safe{Wallet} UI
1. Visit https://app.safe.global
2. Click your Safe name (top-left) → **"+ Add Safe"**
3. Enter each Safe address manually
4. Switch between them in the dropdown

### Method 2: Safe CLI
```bash
safe-cli --address 0xADMIN_SAFE...
safe-cli --address 0xTREASURY_SAFE...
```

### Method 3: Custom Dashboard (Sonny)
- Sonny reads all 4 Safes via Safe Client Gateway
- Shows balances, pending txs, recent activity
- Route actions to correct Safe automatically

---

## Security Checklist

- [ ] All Safe owners use **hardware wallets** (Ledger/Trezor)
- [ ] GUARDIAN_EOA in **cold storage** (offline backup)
- [ ] Deployer **fully revoked** from all contracts
- [ ] Test signature collection (2-of-3, 3-of-5) works
- [ ] Emergency pause tested (COMPLIANCE_SAFE or GUARDIAN)
- [ ] Unpause requires COMPLIANCE + ADMIN quorum
- [ ] Fee withdrawals route to TREASURY_SAFE only
- [ ] Compliance actions require COMPLIANCE_SAFE
- [ ] Protocol upgrades require ADMIN_SAFE (3-of-5)

---

## Costs

| Network | Cost per Safe | Total (4 Safes) |
|---------|---------------|-----------------|
| **Unykorn L1 (7777)** | **$0.00** | **$0.00** ✅ |
| Polygon (137) | ~$0.05 | ~$0.20 |
| Ethereum (1) | ~$50 | ~$200 |

**Unykorn L1 = FREE GAS FOREVER** 💎

---

## Troubleshooting

**"Safe already exists at this address"**
- Safe addresses are deterministic (same owners + threshold = same address)
- If you re-run the script with same owners, it detects the existing Safe
- Just use the predicted address

**"Cannot connect to network unykorn"**
- Start your L1 node: `.\scripts\unykorn.ps1 besu-up`
- Verify: `.\scripts\unykorn.ps1 test-rpc`

**"Not enough signatures"**
- You need the threshold number of hardware wallets connected
- ADMIN_SAFE: 3 signatures required
- TREASURY/COMPLIANCE/OPS: 2 signatures required

---

## Next Steps

1. ✅ **Create 4 Safes** (this guide)
2. ⏭️ **Deploy 16 contracts** (`npm run deploy:energy:unykorn`)
3. ⏭️ **Wire ownerships** (`npm run wire:safes:unykorn`)
4. ⏭️ **Integrate Sonny** with Safe SDK
5. ⏭️ **Deploy Safe services** (Tx, Events, Config, Client Gateway)
6. ⏭️ **Launch** with Safes in full control

**Your existing Safe (`0x1f0f...e9A`) can be retired or used as a test Safe.**

---

**Unykorn L1 = FREE GAS. Safe{Core} = Control Layer. Sonny = Front Door.** 🌟
