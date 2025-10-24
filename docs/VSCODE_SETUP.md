# VS Code Setup Guide

This guide shows how to maximize productivity when developing on Unykorn L1 using VS Code.

---

## Prerequisites

- **VS Code** installed ([Download](https://code.visualstudio.com/))
- **Docker Desktop** installed and running
- **Git** for version control

---

## Quick Start (Recommended Extensions)

When you open this workspace, VS Code will prompt you to install recommended extensions from `.vscode/extensions.json`. Click **Install All** to get:

- **Docker** (`ms-azuretools.vscode-docker`) — Manage containers from VS Code
- **Dev Containers** (`ms-vscode-remote.remote-containers`) — Full dev environment in a container
- **Solidity** (`juanblanco.solidity`) — Smart contract development
- **Prettier** (`esbenp.prettier-vscode`) — Code formatting
- **YAML** (`redhat.vscode-yaml`) — Docker Compose syntax highlighting

---

## Option 1: Dev Container (Isolated Environment)

**Benefits**:

- Docker + all tools pre-installed
- Consistent environment across team
- No local dependency installation

**Setup**:

1. Open VS Code in this folder
2. Press `F1` → "Dev Containers: Reopen in Container"
3. Wait for container to build (~2 minutes first time)
4. You're now inside the dev container!

**Inside the container**:

```bash
# All tools available:
make besu-init
make besu-up
make test-rpc

# Or Polygon-Edge:
make edge-init
make edge-up
```

---

## Option 2: Local Development (Native)

**Prerequisites**:

- Docker Desktop running
- Make installed (Linux/Mac native, Windows via WSL2 or Chocolatey)

**Setup**:

1. Open terminal in VS Code (`Ctrl+` backtick)
2. Run commands directly:

   ```bash
   make besu-init
   make besu-up
   ```

---

## VS Code Tasks (One-Click Commands)

We've configured **VS Code Tasks** for common operations. Access via:

- `Ctrl+Shift+P` → "Tasks: Run Task"
- Or `Terminal` → `Run Task...`

**Available Tasks**:

| Task | What It Does |
|------|--------------|
| `Besu: Initialize` | Generate Besu validator keys + genesis |
| `Besu: Start Network` | Spin up 4 Besu validators + RPC |
| `Besu: Stop Network` | Gracefully stop all Besu containers |
| `Besu: View Logs` | Tail logs from all Besu containers |
| `Edge: Initialize` | Generate Polygon-Edge keys + genesis |
| `Edge: Start Network` | Spin up 3 Edge validators + RPC |
| `Edge: Stop Network` | Stop all Edge containers |
| `RPC: Test ChainId` | Quick RPC health check (expects 7777) |
| `Docker: Clean All` | Remove all containers, networks, volumes |

**Example Workflow**:

1. `Tasks: Run Task` → `Besu: Initialize`
2. `Tasks: Run Task` → `Besu: Start Network`
3. `Tasks: Run Task` → `RPC: Test ChainId` (verify it's running)

---

## Debugging Containers

### View Running Containers

Use the **Docker extension** sidebar:

1. Click Docker icon in left sidebar
2. Expand "Containers"
3. Right-click a container → "View Logs" / "Attach Shell" / "Stop"

### Attach to Container Shell

```bash
# From VS Code terminal
docker exec -it besu-validator-0 bash

# Or use Docker extension: Right-click container → "Attach Shell"
```

---

## Smart Contract Development

### Install Solidity Extension

If not auto-installed, get it manually:

- Press `Ctrl+Shift+X`
- Search "Solidity"
- Install `juanblanco.solidity`

### Configure Solidity Compiler

`.vscode/settings.json` is already configured:

```json
{
  "solidity.compileUsingRemoteVersion": "v0.8.20"
}
```

### Deploy Contracts with Remix

1. Open [Remix IDE](https://remix.ethereum.org/)
2. Injected Provider → MetaMask
3. MetaMask → Switch to "Unykorn L1" (Chain ID 7777)
4. Deploy contract

### Deploy with Hardhat

```bash
# Initialize Hardhat project
npx hardhat init

# Configure hardhat.config.js
module.exports = {
  networks: {
    unykorn: {
      url: "http://localhost:8545",
      chainId: 7777,
      accounts: [
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" // Dev key
      ]
    }
  }
};

# Deploy
npx hardhat run scripts/deploy.js --network unykorn
```

---

## Workspace Settings Explained

`.vscode/settings.json` includes:

```json
{
  "files.exclude": {
    "**/.git": true,
    "**/data": true,           // Hide blockchain data dirs
    "**/scripts/keys": true    // Hide generated keys
  },
  "search.exclude": {
    "**/data": true,
    "**/node_modules": true
  },
  "docker.containers.groupBy": "Compose Project Name",
  "solidity.compileUsingRemoteVersion": "v0.8.20"
}
```

This keeps the file explorer clean and focused on source code.

---

## Git Integration

### Recommended Workflow

```bash
# Create feature branch
git checkout -b feature/add-monitoring

# Make changes, test locally
make besu-up
# ... test ...

# Stage changes
git add .

# Commit (use conventional commits)
git commit -m "feat: add Prometheus metrics endpoint"

# Push
git push origin feature/add-monitoring
```

### Protected Files

`.gitignore` already excludes:

- `data/` — blockchain data (large, regenerable)
- `scripts/keys/` — validator keys (sensitive)
- `.env` — secrets
- `*.log` — logs

**Never commit private keys!**

---

## MetaMask Integration

### Import Network JSON

1. MetaMask → Settings → Networks → "Import from file"
2. Select `MetaMask_Network_7777.json` from workspace root
3. Network "Unykorn L1" now available

### Import Dev Account

1. MetaMask → Account menu → "Import Account"
2. Paste private key from `secrets/DEV_ONLY_accounts.json`
3. You'll see pre-funded balance (1000 ETH on local chain)

---

## Terminal Shortcuts

### Split Terminal

- `Ctrl+Shift+5` — Split terminal (useful for running logs in one pane, commands in another)

### Example Multi-Pane Setup

```
┌─────────────────┬─────────────────┐
│ make besu-logs  │ make test-rpc   │
│ (live logs)     │ (run commands)  │
└─────────────────┴─────────────────┘
```

---

## Recommended VS Code Extensions (Optional)

Beyond the auto-recommended ones:

- **GitLens** (`eamodio.gitlens`) — Advanced Git visualization
- **TODO Highlight** (`wayou.vscode-todo-highlight`) — Highlight TODOs in code
- **Markdown All in One** (`yzhang.markdown-all-in-one`) — Better Markdown editing
- **Thunder Client** (`rangav.vscode-thunder-client`) — Test RPC endpoints visually

Install via:

```bash
code --install-extension eamodio.gitlens
```

---

## Keyboard Shortcuts Cheat Sheet

| Shortcut | Action |
|----------|--------|
| `Ctrl+` backtick | Toggle terminal |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+P` | Quick file open |
| `Ctrl+Shift+F` | Search across files |
| `Ctrl+B` | Toggle sidebar |
| `Ctrl+J` | Toggle panel (terminal/problems) |
| `F5` | Start debugging (if configured) |
| `Ctrl+Shift+T` | Reopen closed editor |

---

## Troubleshooting VS Code

### "Cannot connect to Docker daemon"

**Fix**: Start Docker Desktop, then reload VS Code window (`Ctrl+Shift+P` → "Reload Window")

### "Dev Container failed to start"

**Check**:

1. Docker Desktop is running
2. `.devcontainer/devcontainer.json` is valid JSON
3. Rebuild container: `F1` → "Dev Containers: Rebuild Container"

### "Tasks not showing up"

**Fix**:

- Ensure `.vscode/tasks.json` exists
- Reload window: `Ctrl+Shift+P` → "Reload Window"

### "Terminal shows wrong shell (CMD instead of PowerShell)"

**Fix**:

- `Ctrl+Shift+P` → "Terminal: Select Default Profile" → Choose PowerShell

---

## Performance Tips

### Exclude Large Directories from Search

Already configured in `.vscode/settings.json`:

```json
"search.exclude": {
  "**/data": true,
  "**/node_modules": true
}
```

### Disable Unused Extensions

- Go to Extensions (`Ctrl+Shift+X`)
- Right-click unused extensions → "Disable (Workspace)"

### Use Workspaces

Save this as a workspace for faster loading:

- `File` → `Save Workspace As...` → `unykorn-l1.code-workspace`

---

## Next Steps

1. **Learn the commands**: Run `make help` in terminal
2. **Explore tasks**: `Terminal` → `Run Task...`
3. **Deploy a contract**: Follow Hardhat guide above
4. **Read architecture**: Open `docs/ARCHITECTURE.md`

---

**Pro tip**: Use `Ctrl+Shift+P` → "Preferences: Open Keyboard Shortcuts" to customize shortcuts to your workflow. 🚀
