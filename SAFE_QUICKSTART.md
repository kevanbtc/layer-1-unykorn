# 🎯 Safe{Core} Quick Start Checklist

**Your mission:** Deploy Safe infrastructure on Unykorn L1 (7777), create 4 production multisigs, and integrate Sonny for AI-assisted operations.

---

## ✅ Prerequisites (Do These First)

- [ ] Unykorn L1 nodes running on port 8545
- [ ] All 16 contracts deployed to chainId 7777
- [ ] VaultProofNFT ownership transferred to LaunchVault
- [ ] 5 hardware wallets ready (Ledger/Trezor)
- [ ] Docker installed (for Safe services)

---

## 📦 Phase 1: Deploy Safe Contracts (Day 1)

### Step 1: Clone Safe Deployment Repo

```powershell
cd "c:\Users\Kevan"
git clone https://github.com/safe-global/safe-smart-account.git
cd safe-smart-account
npm install
```

### Step 2: Configure for ChainId 7777

Create `hardhat.config.unykorn.ts`:

```typescript
export default {
  networks: {
    unykorn: {
      url: "http://127.0.0.1:8545",
      chainId: 7777,
      accounts: [process.env.DEPLOYER_PK],
    }
  }
}
```

### Step 3: Deploy Safe Contracts

```powershell
npx hardhat deploy --network unykorn
```

Expected output:
```
✅ Safe Singleton deployed to: 0x...
✅ Safe Proxy Factory deployed to: 0x...
✅ Fallback Handler deployed to: 0x...
✅ MultiSend Library deployed to: 0x...
```

### Step 4: Verify on Sourcify

```powershell
npx hardhat sourcify --network unykorn
```

---

## 🏗️ Phase 2: Stand Up Safe Services (Day 2-3)

### Option A: Docker Compose (Recommended)

Clone Safe infrastructure repo:

```powershell
cd "c:\Users\Kevan"
git clone https://github.com/safe-global/safe-infrastructure.git
cd safe-infrastructure
```

Edit `docker-compose.yml` to add Unykorn L1:

```yaml
services:
  txservice-unykorn:
    image: safeglobal/safe-transaction-service:latest
    environment:
      ETHEREUM_RPC_URL: http://host.docker.internal:8545
      CHAIN_ID: 7777
      ETHEREUM_TRACING_ENABLED: false  # Use event indexing
    ports:
      - "8001:8000"

  events-service:
    image: safeglobal/safe-events-service:latest
    environment:
      SAFE_TX_SERVICE_URL: http://txservice-unykorn:8000
      WEBHOOK_URL: http://host.docker.internal:3000/webhooks/safe
    ports:
      - "8002:8000"

  config-service:
    image: safeglobal/safe-config-service:latest
    ports:
      - "8003:8000"

  client-gateway:
    image: safeglobal/safe-client-gateway:latest
    environment:
      CONFIG_SERVICE_URL: http://config-service:8000
    ports:
      - "8004:8000"
```

Start services:

```powershell
docker-compose up -d
```

### Option B: Manual Setup (Advanced)

See `docs/SAFE_INTEGRATION.md` for detailed manual deployment steps.

---

## 🔐 Phase 3: Create Production Safes (Day 4)

### Step 1: Prepare Hardware Wallets

- [ ] 5 Ledgers for ADMIN_SAFE (3-of-5)
- [ ] 3 Ledgers for TREASURY_SAFE (2-of-3)
- [ ] 3 Ledgers for COMPLIANCE_SAFE (2-of-3)
- [ ] 3 Ledgers for OPS_SAFE (2-of-3)
- [ ] 1 Ledger for GUARDIAN_EOA (cold storage)

### Step 2: Create ADMIN_SAFE

Go to Safe{Wallet} UI (or use SDK):

```typescript
import Safe from '@safe-global/protocol-kit';

const protocolKit = await Safe.init({
  provider: 'http://localhost:8545',
  signer: DEPLOYER_PK,
  predictedSafe: {
    safeAccountConfig: {
      owners: [
        '0xFOUNDER_1',
        '0xFOUNDER_2',
        '0xFOUNDER_3',
        '0xLEGAL_COUNSEL',
        '0xCTO'
      ],
      threshold: 3  // 3-of-5
    }
  }
});

const safeAddress = await protocolKit.getAddress();
console.log('ADMIN_SAFE:', safeAddress);
```

### Step 3: Create Other Safes

Repeat for TREASURY_SAFE (2-of-3), COMPLIANCE_SAFE (2-of-3), OPS_SAFE (2-of-3).

### Step 4: Record Addresses

Add to `.env`:

```env
ADMIN_SAFE=0x...
TREASURY_SAFE=0x...
COMPLIANCE_SAFE=0x...
OPS_SAFE=0x...
GUARDIAN_EOA=0x...
```

---

## 🔄 Phase 4: Wire Ownerships (Day 5)

### Run Automated Script

```powershell
cd "c:\Users\Kevan\layer 1 build"
npm run wire:safes:unykorn
```

### Verify Transfers On-Chain

```powershell
npx hardhat console --network unykorn
```

```javascript
// Check VaultProofNFT owner
const VaultProofNFT = await ethers.getContractAt("VaultProofNFT", "0x...");
const owner = await VaultProofNFT.owner();
console.log("Owner:", owner); // Should be LaunchVault address

// Check ComplianceRegistry owner
const ComplianceRegistry = await ethers.getContractAt("ComplianceRegistry", "0x...");
const compOwner = await ComplianceRegistry.owner();
console.log("Owner:", compOwner); // Should be COMPLIANCE_SAFE

// Check role grants
const LaunchVault = await ethers.getContractAt("LaunchVault", "0x...");
const adminRole = await LaunchVault.DEFAULT_ADMIN_ROLE();
const hasRole = await LaunchVault.hasRole(adminRole, process.env.ADMIN_SAFE);
console.log("ADMIN_SAFE has admin role:", hasRole); // Should be true

// Verify deployer has NO roles
const deployerHasRole = await LaunchVault.hasRole(adminRole, DEPLOYER_ADDRESS);
console.log("Deployer has admin role:", deployerHasRole); // Should be FALSE
```

---

## 🤖 Phase 5: Integrate Sonny (Week 2)

### Step 1: Install Safe SDK in Sonny

```powershell
cd "c:\Users\Kevan\sonny-mcp"  # Your Sonny MCP server
npm install @safe-global/protocol-kit @safe-global/api-kit
```

### Step 2: Add Safe Tools

Create `tools/safe.ts`:

```typescript
import Safe from '@safe-global/protocol-kit';

export const getSafeBalance = async ({ safeAddress, chainId }) => {
  const response = await fetch(
    `http://localhost:8004/v1/chains/${chainId}/safes/${safeAddress}/balances/`
  );
  const data = await response.json();
  return `Safe ${safeAddress} has ${data.length} assets.`;
};

export const getPendingTransactions = async ({ safeAddress, chainId }) => {
  const response = await fetch(
    `http://localhost:8004/v1/chains/${chainId}/safes/${safeAddress}/multisig-transactions/`
  );
  const data = await response.json();
  return `${data.count} pending transactions.`;
};

export const prepareRoleGrant = async ({ contract, role, account }) => {
  const iface = new ethers.Interface(['function grantRole(bytes32,address)']);
  const data = iface.encodeFunctionData('grantRole', [role, account]);
  return {
    to: contract,
    value: '0',
    data,
    operation: 0,
    safeTxGas: 100000,
    description: `Grant ${role} to ${account}`
  };
};
```

### Step 3: Configure Webhooks

In Safe Events Service config, add webhook:

```yaml
webhooks:
  - url: http://localhost:3000/webhooks/safe
    events:
      - OWNER_ADDED
      - OWNER_REMOVED
      - THRESHOLD_CHANGED
      - TRANSACTION_EXECUTED
      - TRANSACTION_FAILED
```

In Sonny MCP server, add webhook handler:

```typescript
app.post('/webhooks/safe', async (req, res) => {
  const event = req.body;
  
  // Log to audit trail
  await auditLog.create({
    type: event.type,
    safeAddress: event.address,
    data: event.data,
    timestamp: new Date()
  });
  
  // Notify users
  if (event.type === 'TRANSACTION_EXECUTED') {
    await notifyUsers(`Transaction ${event.txHash} executed on Safe ${event.address}`);
  }
  
  res.status(200).send('OK');
});
```

---

## 🧪 Phase 6: Smoke Tests (Week 3)

### Test 1: Contribution Flow

```powershell
npx hardhat console --network unykorn
```

```javascript
const LaunchVault = await ethers.getContractAt("LaunchVault", "0x...");
const VaultProofNFT = await ethers.getContractAt("VaultProofNFT", "0x...");

// Contribute 10 UNYETH
const [signer] = await ethers.getSigners();
const tx = await LaunchVault.contribute({ value: ethers.parseEther("10") });
await tx.wait();

// Check NFT minted
const balance = await VaultProofNFT.balanceOf(signer.address);
console.log("NFT Balance:", balance.toString()); // Should be 1

// Check Sonny received webhook
// (Check Sonny logs for event notification)
```

### Test 2: Fee Update via Safe

1. Prepare transaction in Sonny:
   ```
   User: "Update RECMarketplace fee to 0.20%"
   Sonny: "Preparing transaction... [TX DETAILS]"
   ```

2. OPS_SAFE owners sign (2-of-3):
   - Owner 1 signs via Ledger
   - Owner 2 signs via Ledger
   - Transaction executes automatically

3. Verify webhook fired:
   - Check Sonny logs
   - Should see: "Fee updated to 0.20% on RECMarketplace"

### Test 3: Emergency Pause

```javascript
// GUARDIAN_EOA triggers pause
const LaunchVault = await ethers.getContractAt("LaunchVault", "0x...");
const tx = await LaunchVault.pause(); // Requires PAUSER_ROLE
await tx.wait();

// Try to contribute (should fail)
try {
  await LaunchVault.contribute({ value: ethers.parseEther("10") });
  console.log("❌ Contribution succeeded (SHOULD HAVE FAILED)");
} catch (error) {
  console.log("✅ Contribution blocked (expected)");
}

// COMPLIANCE_SAFE unpauses
const unpauseTx = await LaunchVault.unpause(); // COMPLIANCE_SAFE signs
await unpauseTx.wait();

// Try again (should succeed)
const contributeTx = await LaunchVault.contribute({ value: ethers.parseEther("10") });
await contributeTx.wait();
console.log("✅ Contribution succeeded after unpause");
```

---

## 📊 Phase 7: Monitoring Setup (Week 4)

### Grafana Dashboards

Add Safe metrics:

```json
{
  "dashboard": {
    "title": "Safe{Core} on Unykorn L1",
    "panels": [
      {
        "title": "Total Safes Created",
        "targets": [{
          "query": "SELECT COUNT(*) FROM safes WHERE chain_id = 7777"
        }]
      },
      {
        "title": "Total Value Locked (TVL)",
        "targets": [{
          "query": "SELECT SUM(balance_eth) FROM safe_balances WHERE chain_id = 7777"
        }]
      },
      {
        "title": "Pending Transactions",
        "targets": [{
          "query": "SELECT COUNT(*) FROM multisig_transactions WHERE executed = false"
        }]
      }
    ]
  }
}
```

### Alerts (PagerDuty/Slack)

```yaml
alerts:
  - name: "Emergency Pause Triggered"
    condition: "event.type == 'CONTRACT_PAUSED'"
    severity: "critical"
    channels: ["pagerduty", "slack-alerts"]
  
  - name: "Ownership Transferred"
    condition: "event.type == 'OWNERSHIP_TRANSFERRED'"
    severity: "high"
    channels: ["slack-audit"]
  
  - name: "Large Transfer"
    condition: "event.value > 10000000000000000000"  # 10 ETH
    severity: "medium"
    channels: ["slack-treasury"]
```

---

## ✅ Success Checklist

- [ ] Safe contracts deployed to 7777 (verified on Sourcify)
- [ ] All 4 Safe services running (Tx, Events, Config, Client Gateway)
- [ ] 4 production Safes created (ADMIN, TREASURY, COMPLIANCE, OPS)
- [ ] All contract ownerships transferred to Safes
- [ ] Deployer has ZERO admin roles
- [ ] Sonny can read Safe data via Client Gateway
- [ ] Sonny can prepare transactions (role grants, fee updates, etc.)
- [ ] Events Service webhooks delivering to Sonny (100%)
- [ ] Emergency pause tested (GUARDIAN_EOA → pause → COMPLIANCE_SAFE → unpause)
- [ ] Contribution flow works (10 UNYETH → NFT minted → webhook fired)
- [ ] Monitoring dashboards live (Grafana)
- [ ] Alerts configured (PagerDuty/Slack)

---

## 📞 Need Help?

**Phone:** (321) 806-7257  
**Email:** kevan@unykorn.org  
**Docs:** `docs/SAFE_INTEGRATION.md` (comprehensive guide)

---

## 🚀 Next Steps After Launch

1. **XRPL Integration** - Deploy Safe on XRPL EVM Sidechain
2. **Bridge Layer** - Complete LayerZero integration (L1 ↔ Polygon)
3. **Insurance** - Purchase Nexus Mutual $10M coverage
4. **Audit** - Trail of Bits security review
5. **Public Launch** - Update unykorn.org with Sonny chat widget

---

**Safe{Core} + Sonny + Unykorn L1 = The future of RWA infrastructure.** 🌟
