# 🏛️ Unykorn Sovereign L1 (ChainID 7777) - Multi-Validator Setup

Production-grade QBFT consensus configuration for your sovereign blockchain.

---

## 🎯 What This Gives You

- **True ChainID 7777** (not dev mode 1337)
- **Multi-validator Byzantine Fault Tolerant consensus** (QBFT)
- **Persistent state** across restarts
- **Decentralized governance** (2-of-3 or 3-of-5 validator approval)
- **Production-ready architecture**

---

## 📋 Prerequisites

1. Docker and Docker Compose installed
2. 2-5 machines/VMs for validators (can start with 2 on same host for testing)
3. Static IP addresses or domain names for each validator
4. Ports 8545 (RPC), 8546 (WebSocket), 30303 (P2P) open between validators

---

## 🔧 Step 1: Generate Validator Keys

Each validator needs a unique keypair. Run this on each machine:

```powershell
# Create keys directory
mkdir -p docker/validator-keys/validator-1
mkdir -p docker/validator-keys/validator-2

# Generate key for validator 1 (Besu will create this automatically on first run)
# The key will be at: docker/validator-keys/validator-1/key
```

For now, we'll use deterministic keys for testing:

**Validator 1:**
- Private Key: `0x8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63`
- Address: `0xfe3b557e8fb62b89f4916b721be55ceb828dbd73`

**Validator 2:**
- Private Key: `0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3`
- Address: `0x627306090abaB3A6e1400e9345bC60c78a8BEf57`

**Validator 3:**
- Private Key: `0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f`
- Address: `0xf17f52151EbEF6C7334FAD080c5704D77216b732`

---

## 🧬 Step 2: Create Genesis File

**File: `configs/genesis-qbft.json`**

```json
{
  "config": {
    "chainId": 7777,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "qbft": {
      "blockperiodseconds": 2,
      "epochlength": 30000,
      "requesttimeoutseconds": 10
    }
  },
  "nonce": "0x0",
  "timestamp": "0x0",
  "extraData": "0xf87ea00000000000000000000000000000000000000000000000000000000000000000f85494fe3b557e8fb62b89f4916b721be55ceb828dbd7394627306090abab3a6e1400e9345bc60c78a8bef5794f17f52151ebef6c7334fad080c5704d77216b732c080c0",
  "gasLimit": "0x1fffffffffffff",
  "difficulty": "0x1",
  "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
  "coinbase": "0x0000000000000000000000000000000000000000",
  "alloc": {
    "fe3b557e8fb62b89f4916b721be55ceb828dbd73": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    },
    "627306090abab3a6e1400e9345bc60c78a8bef57": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    },
    "f17f52151ebef6c7334fad080c5704d77216b732": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    },
    "9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    }
  }
}
```

**Key Points:**
- `chainId`: 7777
- `extraData`: Contains RLP-encoded list of validator addresses
- `alloc`: Prefunds validator accounts + deployer with 1 billion UNYETH each

---

## 🐳 Step 3: Create Multi-Validator Docker Compose

**File: `docker/docker-compose.qbft.yml`**

```yaml
version: '3.8'

services:
  # Validator Node 1 (Bootnode)
  besu-validator-1:
    image: hyperledger/besu:latest
    container_name: unykorn-validator-1
    restart: unless-stopped
    ports:
      - "8545:8545"   # RPC
      - "8546:8546"   # WebSocket
      - "30303:30303" # P2P
    environment:
      - BESU_LOGGING=INFO
    volumes:
      - besu-qbft-data-1:/opt/besu/data
      - ./configs/genesis-qbft.json:/config/genesis.json:ro
      - ./validator-keys/validator-1:/opt/besu/keys:ro
    command:
      - --genesis-file=/config/genesis.json
      - --data-path=/opt/besu/data
      - --node-private-key-file=/opt/besu/keys/key
      - --rpc-http-enabled=true
      - --rpc-http-host=0.0.0.0
      - --rpc-http-port=8545
      - --rpc-http-api=ETH,NET,WEB3,ADMIN,DEBUG,TXPOOL,QBFT,TRACE
      - --rpc-http-cors-origins=*
      - --rpc-ws-enabled=true
      - --rpc-ws-host=0.0.0.0
      - --rpc-ws-port=8546
      - --rpc-ws-api=ETH,NET,WEB3
      - --host-allowlist=*
      - --min-gas-price=0
      - --miner-enabled=true
      - --miner-coinbase=0xfe3b557e8fb62b89f4916b721be55ceb828dbd73
      - --p2p-enabled=true
      - --p2p-host=0.0.0.0
      - --p2p-port=30303
      - --discovery-enabled=true
      - --nat-method=NONE
    networks:
      - unykorn-qbft-network

  # Validator Node 2
  besu-validator-2:
    image: hyperledger/besu:latest
    container_name: unykorn-validator-2
    restart: unless-stopped
    ports:
      - "8547:8545"   # RPC (alternate port)
      - "8548:8546"   # WebSocket (alternate port)
      - "30304:30303" # P2P (alternate port)
    environment:
      - BESU_LOGGING=INFO
    volumes:
      - besu-qbft-data-2:/opt/besu/data
      - ./configs/genesis-qbft.json:/config/genesis.json:ro
      - ./validator-keys/validator-2:/opt/besu/keys:ro
    command:
      - --genesis-file=/config/genesis.json
      - --data-path=/opt/besu/data
      - --node-private-key-file=/opt/besu/keys/key
      - --rpc-http-enabled=true
      - --rpc-http-host=0.0.0.0
      - --rpc-http-port=8545
      - --rpc-http-api=ETH,NET,WEB3,ADMIN,DEBUG,TXPOOL,QBFT
      - --rpc-http-cors-origins=*
      - --rpc-ws-enabled=true
      - --rpc-ws-host=0.0.0.0
      - --rpc-ws-port=8546
      - --rpc-ws-api=ETH,NET,WEB3
      - --host-allowlist=*
      - --min-gas-price=0
      - --miner-enabled=true
      - --miner-coinbase=0x627306090abab3a6e1400e9345bc60c78a8bef57
      - --p2p-enabled=true
      - --p2p-host=0.0.0.0
      - --p2p-port=30303
      - --discovery-enabled=true
      - --bootnodes=enode://VALIDATOR_1_ENODE@besu-validator-1:30303
      - --nat-method=NONE
    networks:
      - unykorn-qbft-network
    depends_on:
      - besu-validator-1

  # Validator Node 3 (Optional - for 3-of-5 security)
  besu-validator-3:
    image: hyperledger/besu:latest
    container_name: unykorn-validator-3
    restart: unless-stopped
    ports:
      - "8549:8545"
      - "8550:8546"
      - "30305:30303"
    environment:
      - BESU_LOGGING=INFO
    volumes:
      - besu-qbft-data-3:/opt/besu/data
      - ./configs/genesis-qbft.json:/config/genesis.json:ro
      - ./validator-keys/validator-3:/opt/besu/keys:ro
    command:
      - --genesis-file=/config/genesis.json
      - --data-path=/opt/besu/data
      - --node-private-key-file=/opt/besu/keys/key
      - --rpc-http-enabled=true
      - --rpc-http-host=0.0.0.0
      - --rpc-http-port=8545
      - --rpc-http-api=ETH,NET,WEB3,ADMIN,DEBUG,TXPOOL,QBFT
      - --rpc-http-cors-origins=*
      - --rpc-ws-enabled=true
      - --rpc-ws-host=0.0.0.0
      - --rpc-ws-port=8546
      - --rpc-ws-api=ETH,NET,WEB3
      - --host-allowlist=*
      - --min-gas-price=0
      - --miner-enabled=true
      - --miner-coinbase=0xf17f52151ebef6c7334fad080c5704d77216b732
      - --p2p-enabled=true
      - --p2p-host=0.0.0.0
      - --p2p-port=30303
      - --discovery-enabled=true
      - --bootnodes=enode://VALIDATOR_1_ENODE@besu-validator-1:30303
      - --nat-method=NONE
    networks:
      - unykorn-qbft-network
    depends_on:
      - besu-validator-1

volumes:
  besu-qbft-data-1:
    driver: local
  besu-qbft-data-2:
    driver: local
  besu-qbft-data-3:
    driver: local

networks:
  unykorn-qbft-network:
    driver: bridge
```

---

## 🔑 Step 4: Create Validator Key Files

For each validator, create a key file:

**File: `docker/validator-keys/validator-1/key`**
```
8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63
```

**File: `docker/validator-keys/validator-2/key`**
```
c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3
```

**File: `docker/validator-keys/validator-3/key`**
```
ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f
```

**Set Permissions (Linux/Mac):**
```bash
chmod 600 docker/validator-keys/*/key
```

---

## 🚀 Step 5: Launch the Network

### Stop Dev Mode (if running)
```powershell
docker compose -f .\docker\docker-compose.besu.yml down -v
```

### Create Validator Key Directories
```powershell
# Create key files
New-Item -Path "docker\validator-keys\validator-1" -ItemType Directory -Force
New-Item -Path "docker\validator-keys\validator-2" -ItemType Directory -Force
New-Item -Path "docker\validator-keys\validator-3" -ItemType Directory -Force

# Write keys (remove 0x prefix)
"8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63" | Out-File -Encoding ASCII -NoNewline "docker\validator-keys\validator-1\key"
"c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3" | Out-File -Encoding ASCII -NoNewline "docker\validator-keys\validator-2\key"
"ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f" | Out-File -Encoding ASCII -NoNewline "docker\validator-keys\validator-3\key"
```

### Start Validator 1 First (Bootnode)
```powershell
docker compose -f .\docker\docker-compose.qbft.yml up -d besu-validator-1
Start-Sleep 15  # Wait for it to fully start
```

### Get Validator 1 Enode
```powershell
docker logs unykorn-validator-1 2>&1 | Select-String "Enode URL"
```

Copy the enode URL (looks like `enode://abc123...@127.0.0.1:30303`)

### Update docker-compose.qbft.yml

Replace `VALIDATOR_1_ENODE` in the bootnodes lines with the actual enode public key from above.

### Start All Validators
```powershell
docker compose -f .\docker\docker-compose.qbft.yml up -d
```

---

## ✅ Step 6: Verify Network

### Check ChainID
```powershell
(Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
  -ContentType "application/json" `
  -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}').Content
```

**Expected:** `{"jsonrpc":"2.0","id":1,"result":"0x1e61"}` (7777 decimal)

### Check Peer Count
```powershell
(Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
  -ContentType "application/json" `
  -Body '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}').Content
```

**Expected:** `"result":"0x2"` (2 peers if running 3 validators)

### Check Block Production
```powershell
for ($i=0; $i -lt 6; $i++) {
  $block = (Invoke-WebRequest -Uri "http://127.0.0.1:8545" -Method POST `
    -ContentType "application/json" `
    -Body '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}').Content | ConvertFrom-Json
  Write-Host "Block: $($block.result) ($([convert]::ToInt64($block.result, 16)))"
  Start-Sleep -Seconds 3
}
```

**Expected:** Blocks incrementing every 2-3 seconds

---

## 📦 Step 7: Deploy Contracts to Sovereign L1

### Update Hardhat Config

Ensure `hardhat.config.js` has:

```javascript
unykorn: {
  url: "http://127.0.0.1:8545",
  chainId: 7777,
  accounts: process.env.DEPLOYER_PK ? [process.env.DEPLOYER_PK] : [],
  timeout: 60000,
  gasPrice: 0
}
```

### Deploy
```powershell
npx hardhat run scripts/deploy-energy-system.js --network unykorn
```

**Expected Output:**
```
Network: unykorn
ChainId: 7777
Deployer: 0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB
Balance: 1000000000.0 ETH

[... 16 contracts deployed ...]

💾 Saved to: deployments\unykorn.json
```

---

## 🔒 Security Considerations

### For Production:

1. **Generate Fresh Keys**
   ```bash
   # On each validator machine
   openssl rand -hex 32 > /secure/path/validator.key
   ```

2. **Use Hardware Security Modules (HSM)** for validator keys

3. **Separate Machines** - Run each validator on separate servers/clouds:
   - Validator 1: AWS us-east-1
   - Validator 2: Azure westus2
   - Validator 3: GCP europe-west1

4. **Firewall Rules**:
   - Only allow P2P (30303) between validator IPs
   - Restrict RPC (8545) to application servers
   - Block public access to validator nodes

5. **Monitoring**:
   - Set up Prometheus + Grafana for metrics
   - Alert on: peer disconnections, missed blocks, high latency

6. **Backup**:
   - Regular backups of `/opt/besu/data` volumes
   - Store genesis.json and keys in encrypted vault

---

## 📊 Network Governance

With 3 validators, QBFT provides:
- **2-of-3 signatures required** for block finality
- **Byzantine fault tolerance**: Network survives 1 malicious validator
- **No forks**: Immediate finality (no reorgs)

To add/remove validators, use QBFT voting:

```javascript
// Add validator
await admin.qbft.proposeValidatorVote("0xNEW_VALIDATOR_ADDRESS", true)

// Remove validator
await admin.qbft.proposeValidatorVote("0xOLD_VALIDATOR_ADDRESS", false)
```

---

## 🆘 Troubleshooting

### Validators Not Peering

**Check logs:**
```powershell
docker logs unykorn-validator-1 --tail 50
docker logs unykorn-validator-2 --tail 50
```

**Look for:**
- "P2P peer discovery agent started"
- "Enode URL enode://..."

**Fix:**
- Ensure bootnodes enode is correct
- Check firewall allows port 30303
- Verify Docker network connectivity

### Blocks Not Producing

**Symptoms:** `eth_blockNumber` stuck at 0

**Causes:**
- Less than 2 validators online (QBFT needs 2/3 minimum)
- Validators not peered (check `net_peerCount`)
- Genesis extraData missing validator addresses

**Fix:**
- Start at least 2 validators
- Wait 30 seconds for peering
- Check genesis.json extraData is correct RLP encoding

### Wrong ChainID

**Symptoms:** Returns 1337 instead of 7777

**Cause:** Still using dev mode or wrong genesis

**Fix:**
- Ensure `--genesis-file=/config/genesis.json` in docker command
- NOT using `--network=dev`
- Restart with clean volumes: `docker compose down -v`

---

## 🎯 Next Steps

1. ✅ Get 3 validators running and peered
2. ✅ Deploy all 16 contracts to chainId 7777
3. ✅ Set up public RPC endpoint (nginx reverse proxy)
4. ✅ Deploy Blockscout explorer at https://explorer.unykorn.org
5. ✅ Configure DNS: rpc.unykorn.org → Load Balancer → Validators
6. ✅ Implement validator monitoring and alerts
7. ✅ Document validator operator runbooks

---

**You now have a production-grade sovereign blockchain! 🏛️**
