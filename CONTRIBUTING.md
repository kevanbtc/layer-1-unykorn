# Contributing to Unykorn L1

Thank you for your interest in contributing to the Unykorn Layer-1 blockchain project!

## Development Workflow

### Prerequisites

- Docker & Docker Compose
- VS Code (recommended) with Dev Containers extension
- Basic understanding of blockchain consensus mechanisms

### Getting Started

1. **Fork & Clone**
   ```bash
   git clone https://github.com/your-org/unykorn-l1.git
   cd unykorn-l1
   ```

2. **Open in VS Code**
   ```bash
   code .
   ```

3. **Choose Dev Environment**
   - **Option A**: Reopen in Dev Container (recommended)
   - **Option B**: Use local Docker + make commands

4. **Initialize Network**
   ```bash
   # For Besu
   make besu-init
   make besu-up
   
   # OR for Polygon-Edge
   make edge-init
   make edge-up
   ```

## Project Structure

```
.
├── configs/           # Genesis and chain configs
├── docker/            # Docker Compose stacks
├── scripts/           # Bootstrap and utility scripts
│   └── keys/          # Generated validator keys (gitignored)
├── secrets/           # Dev-only accounts (NOT for production)
├── docs/              # Architecture and guides
└── data/              # Node data directories (gitignored)
```

## Making Changes

### Branch Naming

- `feature/your-feature` - New features
- `fix/bug-description` - Bug fixes
- `docs/update-topic` - Documentation updates
- `refactor/component` - Code refactoring

### Commit Messages

Follow conventional commits:

```
feat: add Prometheus metrics endpoint to Besu nodes
fix: correct gas limit in genesis config
docs: update quick start with Windows instructions
chore: bump Besu version to 24.x
```

### Testing Changes

1. **Local Network Test**
   ```bash
   make besu-down && make besu-init && make besu-up
   make test-rpc
   ```

2. **Deploy a Test Contract**
   ```bash
   # Use Remix or Hardhat with local RPC
   # RPC: http://localhost:8545
   # Chain ID: 7777
   ```

3. **Check Logs**
   ```bash
   make besu-logs
   # or
   docker-compose -f docker/docker-compose.besu.yml logs -f
   ```

## Security Guidelines

### DO NOT

- ❌ Commit private keys or mnemonics
- ❌ Use dev accounts (`secrets/DEV_ONLY_accounts.json`) in production
- ❌ Expose RPC ports publicly without authentication
- ❌ Push validator key material to version control

### DO

- ✅ Review `PRODUCTION_SECURITY.md` before deploying
- ✅ Generate fresh validator keys for testnets/mainnet
- ✅ Use `.gitignore` to exclude `scripts/keys/*` and `data/*`
- ✅ Enable JWT auth for production RPC endpoints
- ✅ Run validators behind sentry nodes in production

## Pull Request Process

1. **Update Documentation**
   - If changing configs, update `docs/QUICK_START.md`
   - If adding features, update `ARCHITECTURE.md`

2. **Test Thoroughly**
   - Ensure both Besu and Edge stacks still work
   - Verify RPC endpoints respond correctly
   - Check that MetaMask can connect

3. **Submit PR**
   - Clear title: `feat: add Grafana dashboard for validator metrics`
   - Description: What changed, why, and how to test
   - Link related issues

4. **Code Review**
   - Address reviewer feedback
   - Keep commits atomic and well-documented

## Common Tasks

### Add a New Validator (Besu)

1. Edit `configs/ibftConfigFile.json` → add validator address
2. Run `make besu-init` to regenerate genesis
3. Update `docker/docker-compose.besu.yml` with new node service
4. Restart: `make besu-up`

### Change Chain Parameters

- **Chain ID**: Edit `configs/ibftConfigFile.json` → `chainId`
- **Block Time**: Edit `blockperiodseconds`
- **Gas Limit**: Edit `blockGasLimit`
- After changes: `make besu-init` or `make edge-init`

### Add Monitoring Stack

See `docs/PRODUCTION_SECURITY.md` for Prometheus + Grafana setup.

## Documentation Standards

- Use Markdown for all docs
- Include working code examples
- Keep language clear and concise (like this guide)
- Update `WELCOME.md` for major changes

## Questions?

- Check `docs/TROUBLESHOOTING.md`
- Open a GitHub Discussion
- Review `ARCHITECTURE.md` for technical deep-dive

## License

By contributing, you agree your code is licensed under the project's LICENSE (MIT).

---

**Remember**: This is a sovereign Layer-1. You own the validators, the genesis, the rules. Contribute with that mindset. 🚀
