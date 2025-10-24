# Troubleshooting Guide

Common issues when running your Unykorn Layer-1 blockchain and how to fix them.

---

## 🐳 Docker Issues

### "docker: command not found"

**Cause**: Docker not installed or not in PATH.

**Fix**:

```bash
# Windows (PowerShell as admin)
winget install Docker.DockerDesktop

# macOS
brew install --cask docker

# Linux (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in
```

### "Cannot connect to Docker daemon"

**Cause**: Docker Desktop not running.

**Fix**:

- **Windows/macOS**: Start Docker Desktop application
- **Linux**: `sudo systemctl start docker`

### "port is already allocated"

**Cause**: Another service is using port 8545, 30303, etc.

**Fix**:

```bash
# Find what's using port 8545
# Windows:
netstat -ano | findstr :8545

# macOS/Linux:
lsof -i :8545

# Kill the process or change the port in docker-compose.yml
```

---

## 🔧 Makefile Issues

### "make: command not found" (Windows)

**Cause**: Make not installed on Windows by default.

**Fix Option 1** (WSL2, recommended):

```powershell
wsl --install
# Open WSL terminal, then:
cd /mnt/c/Users/YourName/layer\ 1\ build
make besu-init
```

**Fix Option 2** (Native Windows):

```powershell
# Install via Chocolatey
choco install make

# Or manually run commands from Makefile:
docker-compose -f docker/docker-compose.besu.yml run --rm besu-init
docker-compose -f docker/docker-compose.besu.yml up -d
```

### "make: *** No rule to make target"

**Cause**: Typo in command or missing Makefile.

**Fix**:

```bash
# List available commands
make help

# Ensure you're in the project root directory
cd /path/to/unykorn-l1
pwd  # Should show layer 1 build directory
```

---

## 🚀 Besu Issues

### "Validator not producing blocks"

**Symptoms**: Chain stuck at block 0 or validators logging errors.

**Debugging Steps**:

1. **Check validator logs**:

   ```bash
   make besu-logs
   # or
   docker logs besu-validator-0
   ```

2. **Common causes**:

   - **Wrong genesis**: Validators not listed in `extraData` field
   - **Clock skew**: Validator system clocks out of sync (>2s difference)
   - **Network partition**: Validators can't reach each other (check firewall)

3. **Fix wrong genesis**:

   ```bash
   make besu-down
   make besu-clean  # Remove old data
   make besu-init   # Regenerate genesis
   make besu-up
   ```

### "Peers not connecting"

**Symptoms**: Logs show `Peers connected: 0`.

**Fix**:

1. **Check bootnodes** in `docker-compose.besu.yml`:

   ```yaml
   command:
     - --bootnodes=enode://pubkey@validator-0:30303
   ```

2. **Verify network** in Docker Compose:

   ```bash
   docker network inspect besu-network
   ```

3. **Restart with fresh network**:

   ```bash
   make besu-down
   docker network rm besu-network
   make besu-up
   ```

### "Error: genesis block mismatch"

**Cause**: Data directory has old chain data incompatible with new genesis.

**Fix**:

```bash
make besu-clean  # Removes data/ directories
make besu-init
make besu-up
```

---

## 🔗 Polygon-Edge Issues

### "Failed to generate genesis"

**Symptoms**: `edge-bootstrap.sh` fails with error.

**Debugging**:

```bash
# Run bootstrap script manually to see detailed errors
docker-compose -f docker/docker-compose.edge.yml run --rm edge-init sh

# Inside container:
/scripts/edge-bootstrap.sh
```

**Common causes**:

- **Missing polygon-edge binary**: Verify container has `polygon-edge` in PATH
- **Permission denied**: Ensure `/scripts/keys/edge/` is writable

### "Validators not syncing"

**Symptoms**: Block height stuck, logs show sync errors.

**Fix**:

1. **Check libp2p connectivity**:

   ```bash
   docker exec edge-validator-1 polygon-edge peers list
   ```

2. **Verify genesis matches** across all validators:

   ```bash
   docker exec edge-validator-1 sha256sum /genesis/genesis.json
   docker exec edge-validator-2 sha256sum /genesis/genesis.json
   # Hashes should match
   ```

3. **Restart validators** in sequence:

   ```bash
   docker restart edge-validator-1
   sleep 5
   docker restart edge-validator-2
   ```

---

## 🌐 RPC Issues

### "Cannot connect to localhost:8545"

**Symptoms**: MetaMask/Hardhat can't reach RPC.

**Debugging**:

```bash
# Test RPC with curl
curl -X POST localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Expected response:
# {"jsonrpc":"2.0","id":1,"result":"0x1e61"}  # 0x1e61 = 7777
```

**Fixes**:

1. **Verify RPC node is running**:

   ```bash
   docker ps | grep rpc
   ```

2. **Check port mapping**:

   ```bash
   docker port besu-rpc-node
   # Should show: 8545/tcp -> 0.0.0.0:8545
   ```

3. **Firewall blocking**:

   ```bash
   # Windows: Allow in Windows Defender Firewall
   # macOS: System Preferences → Security → Firewall → Allow Docker
   # Linux: sudo ufw allow 8545
   ```

### "Method not allowed"

**Cause**: RPC method disabled or wrong API module.

**Fix** (Besu):

Edit `docker-compose.besu.yml`:

```yaml
command:
  - --rpc-http-api=ETH,NET,WEB3,ADMIN,DEBUG  # Add missing modules
```

Then restart:

```bash
make besu-down && make besu-up
```

---

## 🦊 MetaMask Issues

### "Chain ID mismatch"

**Symptoms**: MetaMask shows "Invalid chain ID".

**Fix**:

1. **Import network JSON**:
   - MetaMask → Settings → Networks → Import
   - Select `MetaMask_Network_7777.json`

2. **Manually add**:
   - Network Name: Unykorn L1
   - RPC URL: `http://localhost:8545`
   - Chain ID: `7777`
   - Currency Symbol: `UNYETH`

### "Nonce too high"

**Cause**: MetaMask cached old nonce, chain was reset.

**Fix**:

- MetaMask → Settings → Advanced → Clear activity tab data
- Or: MetaMask → Account → Settings → Reset account

### "Insufficient funds for gas"

**Cause**: Account not premined in genesis.

**Fix**:

1. **Import dev account**:
   - MetaMask → Import Account
   - Paste private key from `secrets/DEV_ONLY_accounts.json`

2. **Or premine your address**:
   - Edit `configs/ibftConfigFile.json` → add your address to `alloc`
   - Run `make besu-init` to regenerate genesis

---

## 📊 Performance Issues

### "High CPU usage"

**Causes**:

- Too many peers (gossip overhead)
- Debug logging enabled
- Insufficient resources

**Fixes**:

1. **Limit peers** (Besu):

   ```yaml
   command:
     - --max-peers=25
   ```

2. **Reduce log level**:

   ```yaml
   command:
     - --logging=WARN  # or INFO
   ```

3. **Allocate more resources**:

   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2'
         memory: 4G
   ```

### "Slow block production"

**Causes**:

- Disk I/O bottleneck
- Network latency between validators
- Underpowered VMs

**Fixes**:

1. **Use SSD storage** (not HDD)
2. **Colocate validators** in same region/datacenter
3. **Increase VM specs** (2+ cores, 4GB+ RAM)

---

## 🔍 Debugging Commands

### Besu

```bash
# View live logs
docker logs -f besu-validator-0

# Check sync status
curl -X POST localhost:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# List peers
curl -X POST localhost:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'

# Get latest block
curl -X POST localhost:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Polygon-Edge

```bash
# Check node status
docker exec edge-validator-1 polygon-edge status

# List peers
docker exec edge-validator-1 polygon-edge peers list

# Monitor blocks
docker exec edge-validator-1 tail -f /data/validator-1/blockchain.log
```

---

## 🧹 Clean Slate (Nuclear Option)

**When all else fails**, wipe everything and start fresh:

```bash
# Stop all containers
make besu-down
make edge-down

# Remove all data
rm -rf data/ scripts/keys/

# Rebuild from scratch
make besu-init && make besu-up
# OR
make edge-init && make edge-up
```

**⚠️ WARNING**: This deletes all blockchain data. Only use in development.

---

## 🆘 Still Stuck?

1. **Check logs** with `-f` (follow mode):

   ```bash
   docker-compose -f docker/docker-compose.besu.yml logs -f
   ```

2. **Enable debug logging**:

   ```yaml
   # In docker-compose.yml
   command:
     - --logging=DEBUG
   ```

3. **Search GitHub Issues**:

   - [Besu Issues](https://github.com/hyperledger/besu/issues)
   - [Polygon-Edge Issues](https://github.com/0xPolygon/polygon-edge/issues)

4. **Join Community**:

   - Hyperledger Discord
   - Polygon Discord
   - Stack Overflow (tag: `hyperledger-besu`, `polygon`)

---

## Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| Docker not running | Start Docker Desktop |
| Port conflict | Kill process on port 8545 or change port |
| Genesis mismatch | `make besu-clean && make besu-init` |
| No peers | Check bootnodes in docker-compose.yml |
| RPC not responding | Verify `docker ps` shows RPC container |
| MetaMask can't connect | Import `MetaMask_Network_7777.json` |
| Nonce issues | Reset MetaMask account |
| Low balance | Import dev account from `secrets/` |

---

**Pro tip**: Always check logs first. 90% of issues reveal themselves in the logs. 📋
