# 🚀 Quick Start - Windows Edition

Since you're on **Windows PowerShell**, use the PowerShell script instead of `make`:

## Start Your Layer-1 Blockchain (Choose One)

### Option 1: Hyperledger Besu (Recommended)

```powershell
# Initialize (generate keys + genesis)
.\scripts\unykorn.ps1 besu-init

# Start the network (4 validators + RPC)
.\scripts\unykorn.ps1 besu-up

# Test it's working
.\scripts\unykorn.ps1 test-rpc
```

### Option 2: Polygon-Edge

```powershell
# Initialize
.\scripts\unykorn.ps1 edge-init

# Start
.\scripts\unykorn.ps1 edge-up

# Test
.\scripts\unykorn.ps1 test-rpc
```

## Your Network Details

- **RPC Endpoint**: `http://localhost:8545`
- **Chain ID**: `7777`
- **Network Name**: Unykorn L1

## Connect MetaMask

1. Open MetaMask
2. Settings → Networks → "Add a network manually"
3. Enter:
   - Network Name: **Unykorn L1**
   - RPC URL: **http://localhost:8545**
   - Chain ID: **7777**
   - Currency Symbol: **UNYETH**

## Import Dev Account (Pre-Funded)

1. MetaMask → Account → Import Account
2. Paste this private key:
   ```
   0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```
3. You'll have 1000 ETH on your local chain!

⚠️ **NEVER use this key with real funds! It's public and for local testing only.**

## All Commands

```powershell
.\scripts\unykorn.ps1 help         # Show all commands
.\scripts\unykorn.ps1 besu-logs    # View logs
.\scripts\unykorn.ps1 besu-down    # Stop network
.\scripts\unykorn.ps1 ps           # Show running containers
```

## Next Steps

1. ✅ **Start your network** (commands above)
2. 📖 **Read the docs**: Open `WELCOME.md` or `docs/QUICK_START.md`
3. 🦊 **Connect MetaMask** (instructions above)
4. 🔨 **Deploy a contract** using Remix or Hardhat
5. 🔒 **Plan for production**: Read `docs/PRODUCTION_SECURITY.md`

## Need Help?

- **Troubleshooting**: See `docs/TROUBLESHOOTING.md`
- **VS Code Setup**: See `docs/VSCODE_SETUP.md`
- **Architecture**: See `docs/ARCHITECTURE.md`

---

**You own this Layer-1. Build something amazing.** 🔥
