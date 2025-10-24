# 🎯 Quick Start Guide - Get Your Chain Running NOW

**Time to first block: ~2 minutes**

---

## ⚡ Prerequisites Check

Open PowerShell **as Administrator** and verify:

```powershell
# Check Docker
docker --version
# Should return: Docker version 24.x.x or higher

# Check Docker is running
docker ps
# Should NOT error with "daemon not running"

# Check WSL2 (if on Windows)
wsl --status
# Should show WSL2 as default
```

**Not installed?** 
- Docker Desktop: <https://www.docker.com/products/docker-desktop>
- Enable WSL2: `wsl --install` (requires reboot)

---

## 🚀 Launch Your L1 in 4 Commands

### 1. Navigate to workspace

```powershell
cd "C:\Users\Kevan\layer 1 build"
```

### 2. Initialize genesis & keys

```powershell
.\scripts\unykorn.ps1 besu-init
```

**What this does:**
- Creates `data/` directories for blockchain state
- Generates validator keys
- Writes genesis block configuration
- Sets up bootnode for P2P

**Expected output:**
```
✓ Genesis file created
✓ Validator keys generated
✓ Data directories initialized
```

### 3. Start the blockchain

```powershell
.\scripts\unykorn.ps1 besu-up
```

**What this does:**
- Launches Besu container via Docker Compose
- Starts mining blocks (2-second block time)
- Exposes JSON-RPC on `http://localhost:8545`

**Expected output:**
```
Creating network...
Creating besu-node...
✓ Chain is running
```

### 4. Test RPC endpoint

```powershell
.\scripts\unykorn.ps1 test-rpc
```

**Expected response:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x5"  // Block number in hex (will increase over time)
}
```

**If you see `"result": "0x0"`**, wait 10 seconds and test again. Block 0 is genesis; blocks start at 1.

---

## 🦊 Add to MetaMask (30 seconds)

1. **Open MetaMask** → Click network dropdown → "Add Network"

2. **Enter these values EXACTLY:**

| Field | Value |
|-------|-------|
| Network name | `Unykorn L1 (Local Dev)` |
| New RPC URL | `http://127.0.0.1:8545` |
| Chain ID | `7777` |
| Currency symbol | `UNY` |
| Block explorer URL | *(leave blank)* |

3. **Click Save**

4. **Import dev account:**
   - Click account icon → "Import Account"
   - Paste private key: `0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3`
   - Balance should show **200,000 ETH** (dev premine)

---

## 🎨 Deploy Your First Contract (2 minutes)

### Option 1: Hardhat (Recommended)

```powershell
# Install dependencies (first time only)
npm install

# Compile contracts
npx hardhat compile

# Deploy Greeter contract
npx hardhat run scripts/deploy.ts --network unykorn
```

**Expected output:**
```
🚀 Deploying Greeter to Unykorn L1...
✅ Greeter deployed successfully!
📍 Contract address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

### Option 2: Remix IDE (Browser-based)

1. Go to <https://remix.ethereum.org>
2. Create `Greeter.sol` → paste code from `contracts/Greeter.sol`
3. Compile with Solidity 0.8.20
4. Deploy tab → Environment: "Injected Provider - MetaMask"
5. MetaMask will connect to Unykorn L1 (Chain ID 7777)
6. Click "Deploy" → confirm in MetaMask

---

## 🧪 Run Full RPC Test Suite

```powershell
.\scripts\test-rpc-suite.ps1
```

Tests 18 RPC methods including:
- ✅ Chain ID verification (7777)
- ✅ Block production
- ✅ Peer count
- ✅ Gas price
- ✅ Account balances
- ✅ Transaction estimation

---

## 📊 Monitor Your Chain

### View logs (live)

```powershell
docker compose logs -f besu
```

**What to look for:**
- `Imported new chain segment` → Blocks are being produced ✅
- `blocks=#2, tx=#0` → Block 2 with 0 transactions
- `peers=0` → Normal for single-node dev setup

### Check container status

```powershell
docker compose ps
```

**Should show:**
```
NAME        IMAGE                   STATUS
besu-node   hyperledger/besu:24.1   Up 2 minutes
```

### Quick status command

```powershell
.\scripts\unykorn.ps1 ps
```

Shows running containers + basic metrics.

---

## 🛠️ Common Commands

```powershell
# Stop the chain
.\scripts\unykorn.ps1 down

# Restart the chain
.\scripts\unykorn.ps1 down
.\scripts\unykorn.ps1 besu-up

# Reset chain (delete all blocks, keep keys)
.\scripts\unykorn.ps1 down
Remove-Item -Recurse -Force data/
.\scripts\unykorn.ps1 besu-init
.\scripts\unykorn.ps1 besu-up

# View all available commands
.\scripts\unykorn.ps1
```

---

## 🔥 Send Your First Transaction

### Via MetaMask

1. Switch to Unykorn L1 network
2. Send 1 ETH to any address (or back to yourself)
3. Confirm transaction
4. **Finality: INSTANT** (QBFT consensus has no confirmations needed!)

### Via Hardhat Console

```powershell
npx hardhat console --network unykorn
```

```javascript
const [signer] = await ethers.getSigners();
const balance = await ethers.provider.getBalance(signer.address);
console.log("Balance:", ethers.formatEther(balance));

// Send 1 ETH
const tx = await signer.sendTransaction({
  to: "0x0000000000000000000000000000000000000001",
  value: ethers.parseEther("1.0")
});
await tx.wait();
console.log("Transaction:", tx.hash);
```

---

## 🚨 Troubleshooting

### Problem: `docker compose` not found

**Solution:** Update Docker Desktop to version 24+, or use:
```powershell
docker-compose up -d  # (with hyphen)
```

### Problem: Port 8545 already in use

**Solution:** Another chain (Anvil, Ganache, Geth) is running
```powershell
# Find the process
netstat -ano | findstr :8545

# Kill it (replace PID with actual number)
taskkill /PID <PID> /F

# Or change port in docker-compose.besu.yml:
# ports: - "8546:8545"  # Use 8546 externally
```

### Problem: MetaMask shows "wrong chain ID"

**Solution:** Chain was reset, clear MetaMask's cache
1. MetaMask → Settings → Advanced → "Reset Account"
2. Or delete network and re-add it

### Problem: Blocks not producing

**Solution:** Check validator configuration
```powershell
# View logs for errors
docker compose logs besu | Select-String -Pattern "ERROR"

# Check if genesis has correct validator address
Get-Content configs/ibftConfigFile.json
# The address should match the key generated in data/
```

### Problem: `permission denied` on Linux/WSL

**Solution:** Run with sudo or fix permissions
```bash
sudo chown -R $USER:$USER data/
chmod -R 755 data/
```

---

## 📚 Next Steps

### For Development

- **Read**: `DOCUMENTATION.md` - Complete reference
- **Explore**: `docs/ARCHITECTURE.md` - How consensus works
- **Learn**: `docs/TROUBLESHOOTING.md` - Advanced debugging

### For Production

- **Read**: `docs/MAINNET_LAUNCH.md` - Launch checklist
- **Secure**: `docs/PRODUCTION_SECURITY.md` - Hardening guide
- **Deploy**: `terraform/` - AWS infrastructure

### Join the Community

- **Discord**: [Create your own!]
- **GitHub**: [Your repo here]
- **Docs**: <https://besu.hyperledger.org>

---

## ✅ Success Checklist

- [ ] Docker Desktop running
- [ ] `unykorn.ps1 besu-init` completed without errors
- [ ] `unykorn.ps1 besu-up` shows containers running
- [ ] `test-rpc` returns block number > 0
- [ ] MetaMask connected to Chain ID 7777
- [ ] Dev account shows 200,000 ETH balance
- [ ] Deployed Greeter contract successfully
- [ ] Sent at least one transaction

**All checked?** 🎉 **You now own a sovereign Layer-1 blockchain!**

---

**Your Chain At a Glance:**

| Property | Value |
|----------|-------|
| Chain ID | 7777 |
| Block Time | 2 seconds |
| Consensus | QBFT (Istanbul BFT) |
| Finality | Instant (1 block) |
| Gas Limit | 20,000,000 |
| RPC URL | http://127.0.0.1:8545 |
| WS URL | ws://127.0.0.1:8546 |
| Explorer | Deploy Blockscout (see production/) |

**Time to build something amazing.** 🚀
