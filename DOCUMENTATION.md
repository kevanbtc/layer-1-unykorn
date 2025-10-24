# 📚 Documentation Index

Complete guide to your Unykorn Layer-1 blockchain workspace.

## 🚀 Getting Started (Read These First)

| File | Purpose | When to Read |
|------|---------|-------------|
| **[QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md)** | Windows users start here | Right now! |
| **[WELCOME.md](WELCOME.md)** | Project overview & introduction | First time here |
| **[docs/QUICK_START.md](docs/QUICK_START.md)** | 5-minute setup guide | Ready to launch |

## 📖 Core Documentation

| File | Purpose | Audience |
|------|---------|----------|
| **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** | Technical deep-dive (consensus, EVM, networking) | Developers, architects |
| **[docs/PRODUCTION_SECURITY.md](docs/PRODUCTION_SECURITY.md)** | Security hardening checklist | DevOps, production deployments |
| **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | Common issues & solutions | When things break |
| **[docs/VSCODE_SETUP.md](docs/VSCODE_SETUP.md)** | VS Code productivity guide | VS Code users |

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| **[configs/ibftConfigFile.json](configs/ibftConfigFile.json)** | Genesis template for Chain ID 7777 |
| **[MetaMask_Network_7777.json](MetaMask_Network_7777.json)** | MetaMask network import file |
| **[secrets/DEV_ONLY_accounts.json](secrets/DEV_ONLY_accounts.json)** | Pre-funded dev wallets (⚠️ local only) |
| **[.vscode/tasks.json](.vscode/tasks.json)** | VS Code one-click tasks |
| **[.devcontainer/devcontainer.json](.devcontainer/devcontainer.json)** | Dev Container configuration |

## 🐳 Docker & Scripts

| File | Purpose |
|------|---------|
| **[docker/docker-compose.besu.yml](docker/docker-compose.besu.yml)** | Besu 4-validator stack |
| **[docker/docker-compose.edge.yml](docker/docker-compose.edge.yml)** | Polygon-Edge 3-validator stack |
| **[scripts/unykorn.ps1](scripts/unykorn.ps1)** | PowerShell management (Windows) |
| **[scripts/besu-bootstrap.sh](scripts/besu-bootstrap.sh)** | Besu key generation script |
| **[scripts/edge-bootstrap.sh](scripts/edge-bootstrap.sh)** | Edge key generation script |
| **[Makefile](Makefile)** | Unix/Linux/Mac commands |

## 🤝 Contributing

| File | Purpose |
|------|---------|
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Developer workflow & guidelines |
| **[LICENSE](LICENSE)** | MIT License + security warnings |

## 📂 Directory Structure

```
unykorn-l1/
├── configs/              # Genesis configurations
├── data/                 # Blockchain data (auto-generated, gitignored)
├── docker/               # Docker Compose stacks
├── docs/                 # Documentation (8 guides)
├── scripts/              # Bootstrap & management scripts
│   ├── keys/             # Generated validator keys (gitignored)
│   ├── besu-bootstrap.sh
│   ├── edge-bootstrap.sh
│   └── unykorn.ps1       # Windows PowerShell script
├── secrets/              # Dev-only pre-funded accounts
├── .devcontainer/        # VS Code Dev Container
├── .vscode/              # VS Code tasks & settings
├── QUICKSTART_WINDOWS.md # ⭐ Start here (Windows)
├── WELCOME.md            # Project intro
├── README.md             # GitHub readme
├── CONTRIBUTING.md       # Contribution guide
└── LICENSE               # MIT License
```

## 🎯 Quick Command Reference

### Windows (PowerShell)

```powershell
.\scripts\unykorn.ps1 help         # Show all commands
.\scripts\unykorn.ps1 besu-init    # Initialize Besu
.\scripts\unykorn.ps1 besu-up      # Start Besu
.\scripts\unykorn.ps1 test-rpc     # Test RPC endpoint
.\scripts\unykorn.ps1 besu-logs    # View logs
.\scripts\unykorn.ps1 besu-down    # Stop network
```

### Linux/Mac (Makefile)

```bash
make help           # Show all commands
make besu-init      # Initialize Besu
make besu-up        # Start Besu
make test-rpc       # Test RPC
make besu-logs      # View logs
make besu-down      # Stop network
```

## 🔗 External Resources

- **Besu Docs**: <https://besu.hyperledger.org/>
- **Polygon-Edge Docs**: <https://docs.polygon.technology/edge/>
- **Ethereum JSON-RPC**: <https://ethereum.org/en/developers/docs/apis/json-rpc/>
- **MetaMask**: <https://metamask.io/>

## 🎓 Learning Path

1. **Day 1**: Read `QUICKSTART_WINDOWS.md` → Launch your first network
2. **Day 2**: Connect MetaMask → Deploy a test contract (Remix)
3. **Day 3**: Read `docs/ARCHITECTURE.md` → Understand the internals
4. **Week 2**: Read `docs/PRODUCTION_SECURITY.md` → Plan production
5. **Month 1**: Customize genesis → Add monitoring (Prometheus/Grafana)

## ❓ FAQ

**Q: Which stack should I use, Besu or Edge?**  
A: **Besu** for max Ethereum compatibility and enterprise tooling. **Edge** for speed and simplicity.

**Q: Is this production-ready?**  
A: The dev setup is for local testing. See `docs/PRODUCTION_SECURITY.md` for production hardening.

**Q: Can I change the Chain ID?**  
A: Yes! Edit `configs/ibftConfigFile.json` → `chainId`, then re-run init scripts.

**Q: How do I add more validators?**  
A: See `CONTRIBUTING.md` → "Add a New Validator" section.

**Q: Where are my private keys stored?**  
A: Dev keys in `secrets/DEV_ONLY_accounts.json`. Generated validator keys in `scripts/keys/` (gitignored).

---

**Ready to build? Start with [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md)!** 🚀
