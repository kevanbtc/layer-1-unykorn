# Unykorn L1 Architecture

> **This is a sovereign Layer-1 blockchain.** You own the validators, the consensus, the genesis, and the rules. Not a sidechain, not a rollup—a real L1.

## Chain Parameters (Chain ID: 7777)

- **Name**: Unykorn L1
- **Chain ID**: `7777`
- **Consensus**: QBFT (Besu) or IBFT (Polygon-Edge)
- **Block Time**: 2 seconds
- **Block Gas Limit**: 20,000,000
- **VM**: Ethereum Virtual Machine (EVM)
- **RPC Endpoint**: `http://localhost:8545` (local dev)
- **Network Type**: Permissioned (validator-only block production)

## Core Components

### 1. Consensus Layer

**Choice A: Hyperledger Besu (QBFT)**

- **Algorithm**: Quorum Byzantine Fault Tolerance (QBFT)
- **Finality**: Instant finality (no reorgs)
- **Validator Count**: 4 (configurable)
- **Fault Tolerance**: Tolerates `(n-1)/3` Byzantine faults
- **Use Case**: Enterprise-grade, high security, auditable

**Choice B: Polygon-Edge (IBFT)**

- **Algorithm**: Istanbul Byzantine Fault Tolerance (IBFT)
- **Finality**: Instant finality
- **Validator Count**: 3+ (configurable)
- **Fault Tolerance**: Tolerates `(n-1)/3` Byzantine faults
- **Use Case**: Lightweight, fast iteration, proven scalability

**Why BFT Consensus?**

- No PoW mining overhead
- Predictable block times
- Energy efficient
- Permissioned validator set = known trust model

### 2. State Machine (EVM)

Both stacks implement the Ethereum Virtual Machine with:

- **Opcodes**: Full EVM compatibility (London/Berlin forks enabled)
- **Gas Model**: EIP-1559 base fee + priority fee (configurable)
- **Precompiles**: Standard Ethereum precompiles (ecrecover, sha256, etc.)
- **Account Model**: Nonce-based, secp256k1 signatures

**State Storage**:

- **Database**: LevelDB (Besu) or LevelDB/BoltDB (Edge)
- **State Tries**: Merkle Patricia Tries (MPT) for Ethereum compatibility
- **Pruning**: Optional state pruning for disk savings

### 3. Networking (P2P)

**Besu**:

- **Protocol**: DevP2P (Ethereum's wire protocol)
- **Discovery**: Ethereum Node Records (ENR) + bootnodes
- **Ports**: 30303 (P2P), 8545 (RPC), 8546 (WS)

**Polygon-Edge**:

- **Protocol**: libp2p (modern, modular)
- **Discovery**: Kademlia DHT + static bootnodes
- **Ports**: 1478 (libp2p), 8545 (JSON-RPC), 9632 (gRPC)

**Topology**:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Validator 1 │────▶│ Validator 2 │────▶│ Validator 3 │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
                           │
                    ┌──────▼──────┐
                    │   RPC Node  │ (public-facing)
                    └─────────────┘
```

### 4. Transaction Pipeline

1. **Submission**: User sends signed tx to RPC node
2. **Mempool**: Tx enters local pool, gossips to peers
3. **Validation**: Nonce check, balance check, gas limit
4. **Ordering**: Next proposer selects txs (gas price priority)
5. **Execution**: EVM runs tx, updates state
6. **Finality**: Block signed by 2/3+ validators → finalized

**Mempool Rules** (configurable):

- Min gas price: `1000000000` wei (1 gwei)
- Max pool size: 4096 txs
- Replacement policy: Gas price bump ≥10%

### 5. Accounts & Cryptography

- **Signature Scheme**: ECDSA (secp256k1 curve)
- **Address Format**: Ethereum-style (20 bytes, checksummed)
- **Nonce**: Incremental per-account transaction counter
- **Private Keys**: 256-bit, manage via secrets management (not in-repo)

**Dev Accounts** (local only):

```json
{
  "accounts": [
    {
      "address": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "privateKey": "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    },
    {
      "address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "privateKey": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
    }
  ]
}
```

⚠️ **Never use these in production!** Generate fresh keys for testnets/mainnet.

### 6. Gas & Fee Market

**EIP-1559 Mode** (Besu default):

- **Base Fee**: Algorithmically adjusted per block
- **Priority Fee**: User-set tip to validators
- **Max Fee**: Cap on total gas price
- **Burnt**: Base fee can be burnt (or sent to treasury)

**Fixed Gas Mode** (Edge option):

- **Gas Price**: Fixed `1 gwei` (or configured value)
- **Simpler**: No dynamic adjustment, predictable costs

### 7. Validator Set Management

**Static Validator Set** (current setup):

- Defined in genesis (`extraData` field)
- Requires redeployment to add/remove validators

**Dynamic Validator Set** (future):

- On-chain governance contract (multisig or voting)
- Validators added/removed via transactions
- Requires custom governance logic

**Recommended Production Topology**:

```
Internet
   │
   ▼
┌─────────────┐
│ Sentry Node │ (RPC, filters connections)
└──────┬──────┘
       │ (private network)
       ▼
┌─────────────┐     ┌─────────────┐
│ Validator 1 │────▶│ Validator 2 │ (no public IPs)
└─────────────┘     └─────────────┘
```

### 8. APIs & Integrations

**JSON-RPC** (Ethereum-compatible):

- Methods: `eth_*`, `net_*`, `web3_*`, `txpool_*`
- Port: `8545` (HTTP), `8546` (WebSocket)
- Auth: None (local), JWT (production)

**Admin APIs**:

- `admin_*` - Node management
- `debug_*` - Debugging traces
- `miner_*` - Validator controls (Besu)

**GraphQL** (Besu only):

- Flexible queries for block/tx data
- Endpoint: `/graphql`

**Prometheus Metrics**:

- Endpoint: `/metrics` (port 9545)
- Metrics: Block height, peer count, tx pool, gas used

### 9. Data Model

**Block Structure**:

```
Block {
  header: {
    parentHash, stateRoot, transactionsRoot, receiptsRoot,
    number, gasLimit, gasUsed, timestamp, extraData, ...
  },
  transactions: [ signed tx objects ],
  uncles: [] (always empty in BFT)
}
```

**State Storage**:

- **World State**: All accounts (balances, nonces, code, storage)
- **Tries**: Merkle Patricia Tries for cryptographic proofs
- **Snapshots**: Periodic snapshots for fast sync (optional)

### 10. Upgrades & Forks

**Fork Activation** (Besu):

- Define fork blocks in genesis:
  ```json
  "londonBlock": 0,
  "berlinBlock": 0,
  "istanbulBlock": 0
  ```
- All nodes must upgrade before fork block

**Runtime Upgrades** (future):

- WASM-based runtime (Substrate-style)
- On-chain upgrade voting
- Requires custom implementation

### 11. Security Model

**Threat Surface**:

- P2P gossip (spam, eclipse attacks)
- RPC endpoints (DoS, unauthorized access)
- Validator key compromise (Byzantine behavior)
- State bloat (unbounded storage growth)

**Mitigations**:

- Peer scoring & banning
- Rate limits on RPC
- JWT auth for sensitive APIs
- Gas limits & pruning
- Sentry/validator firewall topology

See `PRODUCTION_SECURITY.md` for hardening checklist.

### 12. Observability

**Logs**:

- Structured JSON logs
- Log levels: `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`

**Metrics**:

- Prometheus scrape endpoint
- Grafana dashboards (community available)

**Tracing**:

- OpenTelemetry support (Besu)
- Jaeger/Zipkin integration

**Block Explorer**:

- Blockscout (EVM-compatible)
- Self-hosted or cloud-managed

### 13. Bridging & Interoperability

**Not included in base kit**, but future options:

- **Light Client Bridge**: Verify L1 finality on Ethereum mainnet
- **Checkpoint Bridge**: Periodic state roots submitted to L1
- **Token Bridge**: Lock/mint bridge for asset transfers
- **Message Passing**: LayerZero, Axelar, or custom relayer

**When to add a bridge**:

- You need external liquidity (USDC, ETH)
- You want to settle to Ethereum mainnet
- You're federating multiple sovereign chains

⚠️ Bridges add attack surface. Audit thoroughly.

## Performance Characteristics

### Besu (QBFT)

- **Block Time**: 2-5 seconds (configurable)
- **TPS**: 200-500 (depends on tx complexity)
- **Finality**: 1-2 blocks (instant for practical purposes)
- **Disk Usage**: ~100GB/year (no pruning), ~20GB (with pruning)

### Polygon-Edge (IBFT)

- **Block Time**: 2 seconds (default)
- **TPS**: 400-700 (simple transfers), 100-200 (complex contracts)
- **Finality**: Instant (BFT consensus)
- **Disk Usage**: ~50GB/year (efficient state management)

## Comparison Matrix

| Feature | Besu (QBFT) | Polygon-Edge (IBFT) |
|---------|-------------|---------------------|
| **Maturity** | Production (enterprise) | Production (proven by Polygon) |
| **Tooling** | Excellent (Ethereum ecosystem) | Good (growing) |
| **Ops Complexity** | Medium | Low |
| **Performance** | High | Very High |
| **Flexibility** | High | Very High |
| **Docs** | Comprehensive | Good |

**Choose Besu if**: You want maximum Ethereum compatibility and enterprise tooling.  
**Choose Edge if**: You want speed, simplicity, and modern architecture.

## Directory Layout

```
unykorn-l1/
├── configs/
│   └── ibftConfigFile.json       # Genesis template (Besu)
├── docker/
│   ├── docker-compose.besu.yml   # 4 validators + RPC (Besu)
│   └── docker-compose.edge.yml   # 3 validators + RPC (Edge)
├── scripts/
│   ├── besu-bootstrap.sh         # Generate Besu keys + genesis
│   ├── edge-bootstrap.sh         # Generate Edge keys + genesis
│   └── keys/                     # Generated keys (gitignored)
│       ├── besu/
│       └── edge/
├── secrets/
│   └── DEV_ONLY_accounts.json    # Pre-funded dev wallets (local only)
├── data/                          # Node data dirs (gitignored)
│   ├── besu-validator-0/
│   ├── edge-validator-1/
│   └── ...
└── docs/
    ├── ARCHITECTURE.md            # This file
    ├── QUICK_START.md             # 5-min setup
    ├── PRODUCTION_SECURITY.md     # Hardening guide
    └── TROUBLESHOOTING.md         # Common issues
```

## Next Steps

1. **Run locally**: `make besu-init && make besu-up`
2. **Deploy testnet**: Provision VMs, generate fresh keys, enable JWT
3. **Add monitoring**: Prometheus + Grafana stack
4. **Harden security**: Firewalls, sentry nodes, backups
5. **Launch mainnet**: Audits, incident response plan, governance

For production deployment, see `PRODUCTION_SECURITY.md`.

---

**You own the chain.** Build with that power. 🚀
