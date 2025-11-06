# Unykorn L1 - Architecture Diagrams

This document provides visual representations of the Unykorn L1 blockchain architecture.

---

## 🏗️ Network Architecture

### Production Network Topology

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INTERNET / PUBLIC ACCESS                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Application Load      │
                    │      Balancer (ALB)     │
                    │   - SSL Termination     │
                    │   - Rate Limiting       │
                    │   - Health Checks       │
                    └────────────┬────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
    ┌─────────▼────────┐ ┌──────▼───────┐ ┌───────▼────────┐
    │  Sentry Node 1   │ │ Sentry Node 2│ │ Block Explorer │
    │  (Public RPC)    │ │ (Public RPC) │ │  (Blockscout)  │
    │  • HTTP/WS RPC   │ │ • HTTP/WS RPC│ │                │
    │  • P2P Peers     │ │ • P2P Peers  │ │                │
    │  • No Mining     │ │ • No Mining  │ │                │
    └─────────┬────────┘ └──────┬───────┘ └────────────────┘
              │                  │
              └──────────────────┼─────────────────────────────┐
                                 │                             │
┌─────────────────────────────────────────────────────────────┼─────┐
│                       PRIVATE SUBNET                        │     │
│                                                             │     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │     │
│  │ Validator 1  │  │ Validator 2  │  │ Validator 3  │◄───┘     │
│  │ (QBFT Node)  │  │ (QBFT Node)  │  │ (QBFT Node)  │          │
│  │ • Block Prod │  │ • Block Prod │  │ • Block Prod │          │
│  │ • Consensus  │  │ • Consensus  │  │ • Consensus  │          │
│  │ • Private IP │  │ • Private IP │  │ • Private IP │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         └──────────────────┼──────────────────┘                  │
│                           │                                      │
│                  ┌────────▼────────┐                            │
│                  │  Validator 4    │                            │
│                  │  (QBFT Node)    │                            │
│                  │  • Block Prod   │                            │
│                  │  • Consensus    │                            │
│                  │  • Private IP   │                            │
│                  └─────────────────┘                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                     MONITORING STACK                              │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐              │
│  │ Prometheus │──▶│  Grafana   │──▶│ AlertMgr   │              │
│  │  (Metrics) │   │(Dashboard) │   │  (Email)   │              │
│  └────────────┘   └────────────┘   └────────────┘              │
└──────────────────────────────────────────────────────────────────┘
```

**Key Design Decisions:**

1. **Sentry Nodes**: Protect validators from DDoS by handling public RPC
2. **Private Subnet**: Validators isolated from internet, only P2P with sentries
3. **Load Balancer**: Distributes traffic, SSL termination, health checks
4. **4 Validators**: Byzantine fault tolerance (3f+1, tolerates 1 failure)
5. **Monitoring**: 24/7 observability with automated alerts

---

## 🔄 Consensus Flow (QBFT)

### Block Production Cycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    QBFT Consensus Algorithm                      │
│                    (2 Second Block Time)                        │
└─────────────────────────────────────────────────────────────────┘

Time: 0s                         Time: 1s                Time: 2s
     ┌────────────┐                   ┌────────────┐         ┌────────────┐
     │ Validator1 │                   │ Validator2 │         │ Validator3 │
     │ (Proposer) │                   │  (Voter)   │         │  (Voter)   │
     └─────┬──────┘                   └─────┬──────┘         └─────┬──────┘
           │                                │                      │
           │ 1. Propose Block               │                      │
           ├───────────────────────────────▶│                      │
           │    (Txs, State Root)           │                      │
           │                                │                      │
           │                                │ 2. Validate Block    │
           │                                ├─────────────────────▶│
           │                                │                      │
           │◀─────────────────────────── 3. Pre-Prepare ──────────┤
           │                                │                      │
           │ 4. Prepare                     │                      │
           ├───────────────────────────────▶│◀─────────────────────┤
           │                                │                      │
           │ 5. Commit (2f+1 votes)         │                      │
           ├───────────────────────────────▶│◀─────────────────────┤
           │                                │                      │
           │ 6. Block Finalized ✅           │                      │
           ├───────────────────────────────▶│─────────────────────▶│
           │    (Instant Finality)          │                      │
           ▼                                ▼                      ▼
    
     Block N                           Block N                Block N
     Finalized                         Finalized              Finalized

┌────────────────────────────────────────────────────────────────────┐
│  QBFT Guarantees:                                                  │
│  • Instant Finality: No chain reorganizations                      │
│  • Byzantine Fault Tolerance: Tolerates f faulty nodes (f < n/3)  │
│  • Deterministic: All nodes agree on same block                    │
│  • Fast: 2-second block time with 1-block finality                │
└────────────────────────────────────────────────────────────────────┘
```

---

## 💾 Data Flow Architecture

### Transaction Lifecycle

```
┌──────────────┐
│    User      │
│  (MetaMask)  │
└──────┬───────┘
       │ 1. Sign Transaction
       │    (Private Key)
       ▼
┌─────────────────────┐
│   JSON-RPC API      │
│  (Sentry Node)      │
│  • eth_sendRawTx    │
└──────┬──────────────┘
       │ 2. Broadcast to Validators
       ▼
┌─────────────────────────────────────┐
│       Transaction Pool (MemPool)    │
│  • Gas Price Ordering               │
│  • Nonce Validation                 │
│  • Signature Verification           │
└──────┬──────────────────────────────┘
       │ 3. Proposer Selects Txs
       ▼
┌─────────────────────────────────────┐
│    Block Proposer (Validator)       │
│  • Batch Transactions                │
│  • Execute EVM Bytecode             │
│  • Update State Root                │
└──────┬──────────────────────────────┘
       │ 4. QBFT Consensus
       ▼
┌─────────────────────────────────────┐
│      Validators Vote (2f+1)         │
│  • Validate State Transition        │
│  • Sign Block                       │
│  • Commit to Chain                  │
└──────┬──────────────────────────────┘
       │ 5. Block Finalized
       ▼
┌─────────────────────────────────────┐
│        Blockchain State             │
│  ┌─────────────────────────────┐   │
│  │  Block N                     │   │
│  │  • State Root: 0xabc...     │   │
│  │  │  Receipts Root: 0xdef... │   │
│  │  • Transactions: [...]      │   │
│  └─────────────────────────────┘   │
└──────┬──────────────────────────────┘
       │ 6. State Updated
       ▼
┌─────────────────────────────────────┐
│      Event Indexer                  │
│  • Block Explorer Updates           │
│  • dApp Subscriptions Notified      │
│  • Analytics Processed              │
└─────────────────────────────────────┘
```

---

## 🏢 Smart Contract Architecture

### Modular Contract System

```
┌───────────────────────────────────────────────────────────────────┐
│                      Smart Contract Layers                         │
└───────────────────────────────────────────────────────────────────┘

Layer 1: Governance & Core Protocol
┌─────────────────────────────────────────────────────────────────┐
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Governance   │  │   Staking    │  │   Treasury   │          │
│  │   System     │  │   Contract   │  │   Contract   │          │
│  │ • Proposals  │  │ • Validators │  │ • Funds Mgmt │          │
│  │ • Voting     │  │ • Rewards    │  │ • Allocation │          │
│  │ • Execution  │  │ • Slashing   │  │ • Vesting    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘

Layer 2: Token Standards & Tokenization
┌─────────────────────────────────────────────────────────────────┐
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   UNY Token  │  │  ERC-3643    │  │  ERC-1400    │          │
│  │   (ERC-20)   │  │  (Security)  │  │ (Regulated)  │          │
│  │ • Transfer   │  │ • Compliance │  │ • Partition  │          │
│  │ • Approve    │  │ • KYC/AML    │  │ • Control    │          │
│  │ • Burn/Mint  │  │ • Transfer   │  │ • Reporting  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘

Layer 3: Business Logic & Applications
┌─────────────────────────────────────────────────────────────────┐
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Marketplace  │  │   Oracles    │  │  Retirement  │          │
│  │   (DEX)      │  │  (Price/KYC) │  │   Credits    │          │
│  │ • Trading    │  │ • Data Feed  │  │ • Offset     │          │
│  │ • Liquidity  │  │ • Attestation│  │ • Registry   │          │
│  │ • Fees       │  │ • Compliance │  │ • Audit      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘

Layer 4: OpenZeppelin Base Libraries
┌─────────────────────────────────────────────────────────────────┐
│  AccessControl │ ReentrancyGuard │ Pausable │ Ownable │ ERC20  │
└─────────────────────────────────────────────────────────────────┘
```

**Design Principles:**

1. **Modularity**: Each contract has single responsibility
2. **Upgradeability**: Proxy patterns for critical contracts
3. **Security**: OpenZeppelin libraries, audited code
4. **Gas Efficiency**: Optimized storage, batch operations
5. **Interoperability**: Standard interfaces (ERC-20, ERC-1400)

---

## 🌐 Deployment Architecture

### Multi-Environment Strategy

```
┌──────────────────────────────────────────────────────────────────┐
│                         Development                               │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Local Docker Compose                                  │     │
│  │  • 4 Besu Validators (1 node each)                     │     │
│  │  • No external dependencies                            │     │
│  │  • Fast iteration (< 2 min setup)                      │     │
│  │  • Use case: Smart contract development               │     │
│  └────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ Git Push
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                   CI/CD (GitHub Actions)                          │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  • Linting (Solhint, ESLint)                           │     │
│  │  • Compilation (Hardhat)                               │     │
│  │  • Testing (Unit, Integration)                         │     │
│  │  • Security Scan (Slither, CodeQL)                     │     │
│  │  • Code Coverage (>95%)                                │     │
│  └────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ Manual Approval
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                         Testnet                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  AWS Cloud (Single Region)                             │     │
│  │  • 4 Validators (t3.medium)                            │     │
│  │  • 2 Sentries (t3.small)                               │     │
│  │  • 1 Block Explorer                                    │     │
│  │  • Public RPC endpoint                                 │     │
│  │  • Use case: Integration testing, partner demos        │     │
│  └────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ Security Audit + Load Testing
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                         Mainnet                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  AWS Cloud (Multi-Region HA)                           │     │
│  │  • 10+ Validators (m5.xlarge, distributed globally)    │     │
│  │  • 5+ Sentries (m5.large, multi-AZ)                    │     │
│  │  • Block Explorer (redundant)                          │     │
│  │  • Multi-region load balancing                         │     │
│  │  • 99.99% uptime SLA                                   │     │
│  │  • Use case: Production dApps, financial institutions  │     │
│  └────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📊 Monitoring & Observability

### Metrics Collection

```
┌───────────────────────────────────────────────────────────────────┐
│                        Metrics Pipeline                            │
└───────────────────────────────────────────────────────────────────┘

 Validators & Sentries           Prometheus               Grafana
┌──────────────────┐         ┌──────────────┐       ┌──────────────┐
│  Besu Metrics    │         │   Time Series│       │  Dashboards  │
│  (HTTP /metrics) │────────▶│   Database   │──────▶│  • Blocks/s  │
│                  │         │              │       │  • TPS       │
│  • Block Height  │         │  • 15s scrape│       │  • Gas Used  │
│  • Peer Count    │         │  • 30d retain│       │  • Peer Cnt  │
│  • Gas Used      │         │  • Alert Rule│       │  • CPU/Mem   │
│  • CPU/Memory    │         │              │       │              │
└──────────────────┘         └──────┬───────┘       └──────────────┘
                                    │
                                    │ Alert Rules
                                    ▼
                             ┌──────────────┐
                             │ AlertManager │
                             │  • Email     │──▶ 📧 DevOps Team
                             │  • Slack     │──▶ 💬 Ops Channel
                             │  • PagerDuty │──▶ 📱 On-Call
                             └──────────────┘

Alert Conditions:
• Validator offline > 5 min
• Block production stopped > 30 sec
• Peer count < 3
• Disk space > 85%
• Memory usage > 90%
```

---

## 🔐 Security Architecture

### Defense in Depth

```
┌───────────────────────────────────────────────────────────────────┐
│                         Security Layers                            │
└───────────────────────────────────────────────────────────────────┘

Layer 1: Network Security
┌─────────────────────────────────────────────────────────────────┐
│  • AWS VPC with private subnets                                 │
│  • Security Groups (firewall rules)                             │
│  • NACLs (network ACLs)                                         │
│  • DDoS protection (AWS Shield)                                 │
│  • WAF rules on ALB                                             │
└─────────────────────────────────────────────────────────────────┘

Layer 2: Infrastructure Security
┌─────────────────────────────────────────────────────────────────┐
│  • SSH key-based authentication only                            │
│  • Fail2ban for brute force protection                          │
│  • Automatic security patches                                   │
│  • Encrypted EBS volumes                                        │
│  • IAM roles with least privilege                               │
└─────────────────────────────────────────────────────────────────┘

Layer 3: Application Security
┌─────────────────────────────────────────────────────────────────┐
│  • JWT authentication for RPC                                   │
│  • Rate limiting per IP                                         │
│  • CORS policies                                                │
│  • TLS 1.3 encryption                                           │
│  • API key management                                           │
└─────────────────────────────────────────────────────────────────┘

Layer 4: Smart Contract Security
┌─────────────────────────────────────────────────────────────────┐
│  • Third-party audits                                           │
│  • Automated security scanning (Slither)                        │
│  • Formal verification                                          │
│  • Bug bounty program                                           │
│  • Emergency pause mechanisms                                   │
└─────────────────────────────────────────────────────────────────┘

Layer 5: Operational Security
┌─────────────────────────────────────────────────────────────────┐
│  • Multi-sig wallets for admin functions                        │
│  • Hardware key storage (Ledger, Trezor)                        │
│  • 24/7 monitoring and alerting                                 │
│  • Incident response procedures                                 │
│  • Regular security drills                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📈 Scalability Strategy

### Horizontal Scaling Plan

```
Phase 1: Launch (Q1 2025)          Phase 2: Growth (Q2-Q3 2025)
┌──────────────────────┐           ┌──────────────────────┐
│ 4 Validators         │           │ 10 Validators        │
│ 2 Sentries           │──────────▶│ 5 Sentries           │
│ 1 Block Explorer     │           │ 2 Block Explorers    │
│ 500 TPS              │           │ 1000 TPS             │
└──────────────────────┘           └──────────────────────┘
                                              │
                                              │
                                              ▼
Phase 3: Scale (Q4 2025)           Phase 4: Global (2026)
┌──────────────────────┐           ┌──────────────────────┐
│ 25 Validators        │           │ 50+ Validators       │
│ 10 Sentries          │──────────▶│ 20+ Sentries         │
│ Multi-region         │           │ Global distribution  │
│ 2000 TPS             │           │ 5000+ TPS            │
│ Layer 2 Research     │           │ Layer 2 Rollups      │
└──────────────────────┘           └──────────────────────┘

Scaling Techniques:
• Add more validator nodes (QBFT supports dynamic sets)
• Horizontal scaling of RPC endpoints
• Layer 2 rollups for unlimited TPS
• State pruning to reduce storage
• Optimized EVM gas costs
```

---

## 🔗 Integration Points

### External Systems

```
                    ┌─────────────────────┐
                    │   Unykorn L1 Core   │
                    └──────────┬──────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐
    │   Wallets   │    │   Bridges   │    │   Oracles   │
    ├─────────────┤    ├─────────────┤    ├─────────────┤
    │ • MetaMask  │    │ • Ethereum  │    │ • Chainlink │
    │ • Ledger    │    │ • Polygon   │    │ • Band      │
    │ • Trust     │    │ • LayerZero │    │ • Custom    │
    └─────────────┘    └─────────────┘    └─────────────┘
           │                   │                   │
           └───────────────────┼───────────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐
    │  Custody    │    │  Analytics  │    │   DeFi      │
    ├─────────────┤    ├─────────────┤    ├─────────────┤
    │ • Fireblocks│    │ • The Graph │    │ • DEXs      │
    │ • Copper    │    │ • Dune      │    │ • Lending   │
    │ • Anchorage │    │ • Custom    │    │ • Staking   │
    └─────────────┘    └─────────────┘    └─────────────┘
```

---

## 📝 Notes

- All diagrams are conceptual representations
- Production deployment may vary based on requirements
- Refer to specific documentation for implementation details
- Architecture evolves with network growth and requirements

For more details:
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical deep dive
- [PRODUCTION_SECURITY.md](PRODUCTION_SECURITY.md) - Security hardening
- [MAINNET_LAUNCH.md](MAINNET_LAUNCH.md) - Deployment procedures
