# 🦄 Unykorn L1 - Sovereign Layer-1 Blockchain

**Chain ID: 7777** | **Block Time: 2s** | **Consensus: QBFT** | **Status: Production-Ready** 🚀

A complete, sovereign Layer-1 blockchain built on Hyperledger Besu with QBFT consensus. Full EVM compatibility, instant finality, production monitoring, and cloud deployment automation.

**🔗 White-Label Safe App**: `c:\Users\Kevan\unykorn-safe-app` - Professional RWA tokenization interface for Safe{Wallet} multisig custody ([See Safe App README](../unykorn-safe-app/README.md))

---

## ⚡ 60-Second Quick Start (Windows)

```powershell
# 1. Start Docker Desktop (ensure it's running)

# 2. Initialize your blockchain
cd "C:\Users\Kevan\layer 1 build"
.\scripts\unykorn.ps1 besu-init

# 3. Launch the chain
.\scripts\unykorn.ps1 besu-up

# 4. Test RPC
.\scripts\unykorn.ps1 test-rpc
# Should return: {"jsonrpc":"2.0","id":1,"result":"0x..."}

# 5. Add to MetaMask
# Network: Unykorn L1 (Local Dev)
# RPC URL: http://127.0.0.1:8545
# Chain ID: 7777
# Currency: UNY
```

**✅ Your blockchain is live!** Read [QUICK_START.md](docs/QUICK_START.md) for MetaMask setup and first contract deployment.

---

## 🎯 What You Get

### **Complete Development Environment**
- ✅ Hyperledger Besu 24.1 with QBFT consensus
- ✅ Polygon-Edge alternative configuration
- ✅ Docker Compose stacks (dev + production)
- ✅ VS Code integration (tasks, Dev Container, debugging)
- ✅ PowerShell management script (Windows-native)
- ✅ Hardhat deployment suite with sample contracts
- ✅ RPC test suite (18 comprehensive tests)

### **Production Infrastructure**
- ✅ 4-validator + 2-sentry architecture
- ✅ Prometheus + Grafana monitoring stack
- ✅ Blockscout block explorer
- ✅ Nginx reverse proxy with rate limiting
- ✅ Terraform AWS deployment (VPC, EC2, ALB, CloudWatch)
- ✅ Automated key generation & backup scripts
- ✅ Alert rules for validator health

### **Enterprise Documentation**
- ✅ 40+ pages of comprehensive guides
- ✅ Mainnet launch checklist (8-phase process)
- ✅ Production security hardening guide
- ✅ Troubleshooting playbooks
- ✅ Operational runbooks
- ✅ Architecture deep-dive

---

## 📊 Network Specifications

| Property | Value | Notes |
|----------|-------|-------|
| **Chain ID** | `7777` | Your sovereign identity |
| **Block Time** | `2 seconds` | Fast UX, instant finality |
| **Gas Limit** | `20,000,000` | ~3x Ethereum mainnet |
| **Consensus** | `QBFT` | Istanbul BFT, Byzantine fault tolerant |
| **Finality** | `Instant` | 1 block = final (no reorgs) |
| **EVM Version** | `Paris` | Full Ethereum compatibility |
| **Min Gas Price** | `1 Gwei` | Configurable |
| **Throughput** | `200-500 TPS` | Besu / 400-700 TPS Edge |

---

## 🚀 Usage Scenarios

### **Scenario 1: Local Development (2 minutes)**

Perfect for smart contract development, testing, and prototyping.

```powershell
.\scripts\unykorn.ps1 besu-init
.\scripts\unykorn.ps1 besu-up

# Deploy a contract
npm install
npx hardhat run scripts/deploy.ts --network unykorn
```

### **Scenario 2: Production Mainnet Launch (6-8 weeks)**

Full sovereign L1 with monitoring, security, and public RPC.

1. **Weeks 1-2**: Security audit, key generation on air-gapped hardware
2. **Weeks 2-3**: Deploy AWS infrastructure via Terraform
3. **Weeks 3-4**: Configure validators, sentries, monitoring
4. **Weeks 4-5**: Deploy Blockscout explorer, Grafana dashboards
5. **Weeks 5-6**: Security penetration testing
6. **Weeks 6-7**: Soft launch (invite-only), public announcement
7. **Week 7+**: Ongoing operations, community growth

**Read**: [docs/MAINNET_LAUNCH.md](docs/MAINNET_LAUNCH.md) for complete checklist.

---

## 🛠️ Development Tools

### **Hardhat Integration**

```powershell
# Compile contracts
npx hardhat compile

# Deploy to local dev chain
npx hardhat run scripts/deploy.ts --network unykorn

# Deploy to production mainnet
npx hardhat run scripts/deploy.ts --network mainnet
```

### **RPC Testing**

```powershell
.\scripts\test-rpc-suite.ps1
# Tests: Chain ID, block production, peers, gas price, balances, and 12 more
```

### **VS Code Integration**

- `Ctrl+Shift+B` → Build menu (besu-up, besu-down, test-rpc, logs)
- Dev Container support
- Debugging configurations
- Recommended extensions

**Read**: [docs/VSCODE_SETUP.md](docs/VSCODE_SETUP.md)

---

## 🔐 Security

### **⚠️ CRITICAL WARNINGS**

1. **NEVER** use development keys in production
2. **ALWAYS** generate production keys on air-gapped hardware
3. **ENABLE** 2FA on all cloud provider accounts
4. **RESTRICT** validator nodes to private subnets
5. **BACKUP** validator keys to 3 locations (3-2-1 rule)
6. **ROTATE** JWT secrets quarterly
7. **AUDIT** smart contracts before mainnet deployment

**Read**: [docs/PRODUCTION_SECURITY.md](docs/PRODUCTION_SECURITY.md) for complete guide.

---

## 📖 Documentation Index

| Document | Purpose | Audience |
|----------|---------|----------|
| **[QUICK_START.md](docs/QUICK_START.md)** | Get running in 2 minutes | Everyone |
| **[QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md)** | Windows-specific instructions | Windows users |
| **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** | Consensus, EVM, networking deep-dive | Developers |
| **[MAINNET_LAUNCH.md](docs/MAINNET_LAUNCH.md)** | 8-phase launch checklist | DevOps/Founders |
| **[PRODUCTION_SECURITY.md](docs/PRODUCTION_SECURITY.md)** | Hardening & best practices | Security teams |
| **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | Common issues & solutions | Support teams |
| **[VSCODE_SETUP.md](docs/VSCODE_SETUP.md)** | IDE integration & tasks | Developers |

---

## 🌐 Production Deployment

### **AWS Deployment (Terraform)**

```powershell
cd terraform
terraform init
terraform plan
terraform apply

# Outputs:
# - Validator private IPs
# - Sentry public IPs
# - ALB DNS name (public RPC endpoint)
```

**Read**: [docs/MAINNET_LAUNCH.md](docs/MAINNET_LAUNCH.md) for step-by-step guide.

---

## 📜 License

MIT License - see [LICENSE](LICENSE) for details.

### **⚠️ SECURITY NOTICE**

This software manages cryptographic keys and blockchain infrastructure. You are **solely responsible** for securing your deployment, backing up keys, and compliance with applicable laws.

**NO WARRANTY** is provided. Use at your own risk.

---

## 🎉 Ready to Launch?

### **Next Steps:**

1. **Local Dev**: Follow [QUICK_START.md](docs/QUICK_START.md) (2 minutes)
2. **Deploy Contract**: Run `npx hardhat run scripts/deploy.ts --network unykorn`
3. **Production**: Read [MAINNET_LAUNCH.md](docs/MAINNET_LAUNCH.md) (6-8 weeks)

### **You Now Have:**

- ✅ A sovereign Layer-1 blockchain (Chain ID 7777)
- ✅ Full EVM compatibility (Solidity, Hardhat, MetaMask)
- ✅ Production monitoring (Prometheus, Grafana, alerts)
- ✅ Cloud deployment automation (Terraform + AWS)
- ✅ 40+ pages of documentation
- ✅ Security best practices

**Time to build the future.** 🚀

---

**Built with ❤️ by the Unykorn L1 team**

*"Your chain. Your rules. Your sovereignty."*
