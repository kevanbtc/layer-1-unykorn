# Production Security Hardening Guide

> **This guide covers transitioning from local dev to production-grade security.** The dev setup is intentionally open for ease of testing. Production requires locking down every attack surface.

---

## 🔴 CRITICAL: Do NOT Deploy Without These Steps

### 1. Key Management

#### ❌ NEVER Do This

- Use dev accounts from `secrets/DEV_ONLY_accounts.json` in production
- Commit validator private keys to version control
- Store keys in cloud storage without encryption
- Share validator keys between nodes
- Use keys generated on internet-connected machines

#### ✅ DO This

**Generate Validator Keys Offline**

```bash
# On air-gapped machine (no network connection)
# Besu:
besu --data-path=/secure/path/validator-1 public-key export --to=/secure/path/validator-1/key.pub

# Polygon-Edge:
polygon-edge secrets init --data-dir /secure/path/validator-1
```

**Store Keys Securely**

- **Hardware Security Module (HSM)**: YubiHSM, AWS CloudHSM
- **Encrypted USB drives**: LUKS, VeraCrypt
- **Secrets management**: HashiCorp Vault, AWS Secrets Manager
- **Backup strategy**: Encrypted, geographically distributed, tested restoration

**Key Rotation Policy**

- Rotate RPC API keys quarterly
- Rotate validator keys annually (requires governance process)
- Immediately rotate if compromise suspected

### 2. Network Topology

#### Production Architecture

```
┌──────────────────────────────────────────┐
│  Internet (Public)                        │
└────────────────┬─────────────────────────┘
                 │
         ┌───────▼────────┐
         │  Load Balancer  │ (CloudFlare, AWS ALB)
         └───────┬────────┘
                 │
    ┌────────────┴────────────┐
    ▼                         ▼
┌─────────┐             ┌─────────┐
│ Sentry 1│             │ Sentry 2│  (Public IPs, firewall rules)
└────┬────┘             └────┬────┘
     │                       │
     └───────┬───────────────┘
             │ (Private VPC/VLAN)
    ┌────────┴────────┐
    ▼                 ▼
┌──────────┐     ┌──────────┐
│Validator1│────▶│Validator2│  (NO public IPs, strict firewall)
└──────────┘     └──────────┘
      │               │
      └───────┬───────┘
              ▼
         ┌──────────┐
         │Validator3│
         └──────────┘
```

**Sentry Nodes** (RPC-facing):

- Public IP, rate-limited
- No validator keys
- Filter incoming connections (whitelist known peers)
- DDoS protection (CloudFlare, fail2ban)

**Validator Nodes** (consensus-only):

- Private network only
- Firewall: block all inbound except sentry IPs
- No direct internet access
- Run in separate security groups/VPCs

#### Firewall Rules (Example: iptables)

**Validator Node**:

```bash
# Block all inbound except from sentry nodes
iptables -A INPUT -s <sentry-1-IP> -p tcp --dport 30303 -j ACCEPT
iptables -A INPUT -s <sentry-2-IP> -p tcp --dport 30303 -j ACCEPT
iptables -A INPUT -j DROP

# Allow outbound to other validators (private IPs only)
iptables -A OUTPUT -d <validator-2-private-IP> -p tcp --dport 30303 -j ACCEPT
```

**Sentry Node**:

```bash
# Rate limit RPC
iptables -A INPUT -p tcp --dport 8545 -m limit --limit 100/sec -j ACCEPT
iptables -A INPUT -p tcp --dport 8545 -j DROP

# Allow P2P from validators (private network)
iptables -A INPUT -s <validator-private-subnet> -p tcp --dport 30303 -j ACCEPT
```

### 3. RPC API Security

#### Authentication

**Enable JWT for Engine API** (Besu):

```bash
# Generate JWT secret
openssl rand -hex 32 > /secure/path/jwt-secret.hex

# Start Besu with JWT
besu \
  --engine-jwt-secret=/secure/path/jwt-secret.hex \
  --engine-host-allowlist=localhost,validator-rpc \
  ...
```

**Enable HTTPS with TLS**:

```bash
# Generate cert (use Let's Encrypt for prod)
certbot certonly --standalone -d rpc.unykorn.com

# Configure nginx reverse proxy
server {
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/rpc.unykorn.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rpc.unykorn.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8545;
        limit_req zone=rpc_limit burst=20;
    }
}
```

#### Rate Limiting

**Nginx** (recommended):

```nginx
http {
    limit_req_zone $binary_remote_addr zone=rpc_limit:10m rate=10r/s;
    
    server {
        location / {
            limit_req zone=rpc_limit burst=20 nodelay;
            proxy_pass http://localhost:8545;
        }
    }
}
```

**CloudFlare** (DDoS + rate limit):

- Enable "Under Attack" mode if DDoS detected
- Set rate limit: 300 requests/5 minutes per IP
- Block countries with no legitimate users

#### Disable Dangerous APIs

**Besu**:

```bash
besu \
  --rpc-http-api=ETH,NET,WEB3 \   # NO admin, debug, miner
  --rpc-ws-enabled=false \         # Disable WebSockets if not needed
  --host-allowlist=rpc.unykorn.com \
  ...
```

**Polygon-Edge**:

```bash
polygon-edge server \
  --jsonrpc-disable eth_signTransaction,admin_* \
  ...
```

### 4. Monitoring & Alerting

#### Prometheus Metrics

**Scrape Config** (`prometheus.yml`):

```yaml
scrape_configs:
  - job_name: 'besu-validators'
    static_configs:
      - targets:
          - validator-1:9545
          - validator-2:9545
          - validator-3:9545
    metrics_path: /metrics
```

**Critical Alerts**:

```yaml
# alerting-rules.yml
groups:
  - name: blockchain
    rules:
      - alert: ValidatorDown
        expr: up{job="besu-validators"} == 0
        for: 2m
        annotations:
          summary: "Validator {{ $labels.instance }} is down"
      
      - alert: MissedProposals
        expr: increase(besu_blockchain_difficulty_total[5m]) < 60
        annotations:
          summary: "Validator missing block proposals"
      
      - alert: HighPeerChurn
        expr: rate(besu_peers_connected[5m]) > 10
        annotations:
          summary: "Abnormal peer connect/disconnect rate"
```

#### Log Aggregation

**Recommended Stack**:

- **Loki** + **Promtail** → Grafana (lightweight)
- **ELK Stack** (Elasticsearch + Logstash + Kibana) (heavy, powerful)

**Log to structured JSON** (Besu):

```bash
besu --logging=JSON ...
```

**Ship logs to SIEM** (for compliance):

- Splunk
- Datadog
- AWS Security Hub

### 5. OS-Level Hardening

#### Ubuntu/Debian

```bash
# Keep system updated
apt update && apt upgrade -y

# Install fail2ban (auto-ban brute force attempts)
apt install fail2ban
systemctl enable fail2ban

# Disable root SSH login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Enable automatic security updates
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Harden kernel
cat >> /etc/sysctl.conf <<EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF
sysctl -p
```

#### User Permissions

```bash
# Create dedicated user (no sudo)
useradd -m -s /bin/bash besu
chown -R besu:besu /opt/besu /data/besu

# Run validator as non-root
su - besu
/opt/besu/bin/besu --data-path=/data/besu/validator-1 ...
```

### 6. Backups & Disaster Recovery

#### What to Backup

- **Validator Keys**: Encrypted, offline, multiple locations
- **Genesis File**: Version controlled + S3/backup
- **Database Snapshots**: Daily snapshots of chain data

#### Backup Strategy

**Database Snapshots** (daily):

```bash
#!/bin/bash
# Snapshot Besu data directory
tar -czf /backups/besu-$(date +%Y%m%d).tar.gz /data/besu/validator-1/database
aws s3 cp /backups/besu-$(date +%Y%m%d).tar.gz s3://unykorn-backups/

# Prune old backups (keep 30 days)
find /backups -type f -mtime +30 -delete
```

**Key Backup** (encrypted):

```bash
# Encrypt validator keys
gpg --symmetric --cipher-algo AES256 /secure/validator-1/key > validator-1.key.gpg

# Store in multiple locations:
# 1. Encrypted USB drive (safe)
# 2. AWS S3 (encrypted bucket)
# 3. Geographic backup (different region)
```

**Test Restoration**:

- Monthly drill: Restore from backup and sync node
- Verify RPC endpoints respond
- Check validator can propose blocks

### 7. Incident Response Plan

#### Preparation

1. **Runbook**: Document "validator down" recovery steps
2. **On-call rotation**: 24/7 coverage for critical issues
3. **Emergency contacts**: Validator operators, security team
4. **Kill switch**: Ability to halt chain if critical bug found

#### Response Playbook

**Validator Compromise Detected**:

1. Isolate compromised validator (firewall block)
2. Rotate validator keys (generate new, update genesis if needed)
3. Audit logs for unauthorized transactions
4. Notify other validators
5. Post-mortem: How did breach occur?

**DDoS Attack on RPC**:

1. Enable CloudFlare "Under Attack" mode
2. Scale sentry nodes horizontally
3. Tighten rate limits (10 req/s → 5 req/s)
4. Identify attack source, block IPs/ASNs

**Critical Bug (e.g., consensus halt)**:

1. Alert all validators immediately
2. Coordinate emergency upgrade
3. Test fix on staging network first
4. Deploy simultaneously to avoid fork
5. Communicate downtime to users

### 8. Compliance & Audits

#### Smart Contract Audits

If deploying critical contracts (bridges, governance):

- **Firms**: Trail of Bits, OpenZeppelin, Quantstamp
- **Scope**: All custom contracts + token economics
- **Timeline**: 4-6 weeks before mainnet launch

#### Infrastructure Audit

- **Penetration testing**: Simulate attacks on RPC/validators
- **Configuration review**: Audit firewall rules, key storage
- **Social engineering**: Test team's response to phishing

#### Legal Compliance

Consult legal counsel for:

- Jurisdiction (where are validators hosted?)
- KYC/AML requirements (if bridging to regulated assets)
- Terms of service for RPC users
- Data privacy (GDPR, CCPA)

### 9. Governance & Upgrade Process

#### Adding/Removing Validators

**Option 1: Off-chain governance** (current):

1. Multisig of founding validators approves change
2. New genesis generated with updated validator set
3. Coordinated network restart (downtime: ~5 minutes)

**Option 2: On-chain governance** (future):

1. Deploy validator registry contract
2. Voting mechanism (token-weighted or validator-weighted)
3. Automatic validator set updates (no restart needed)

#### Network Upgrades (Hard Forks)

**Testnet First**:

```bash
# 1. Deploy upgrade to testnet (Chain ID 7778)
# 2. Run for 1 week, monitor metrics
# 3. Fix any issues
# 4. Coordinate mainnet upgrade
```

**Communication**:

- Announce 2 weeks in advance
- Publish upgrade guide
- Notify dapp developers, RPC users
- Set fork block height (e.g., block 1,000,000)

**Rollback Plan**:

- Keep old binaries available
- Snapshot state before upgrade
- If critical bug: coordinate rollback to pre-fork block

### 10. Security Checklist (Pre-Launch)

#### Infrastructure

- [ ] Validators on private network (no public IPs)
- [ ] Sentry nodes with rate limiting
- [ ] Firewall rules tested (allow-list only)
- [ ] TLS/HTTPS on all public RPC endpoints
- [ ] JWT auth enabled for engine API

#### Keys & Secrets

- [ ] Validator keys generated offline
- [ ] Private keys NEVER in version control
- [ ] Encrypted backups in 3+ locations
- [ ] HSM considered for high-value validators
- [ ] Dev accounts (`secrets/DEV_ONLY_accounts.json`) REMOVED

#### Monitoring

- [ ] Prometheus + Grafana dashboards
- [ ] Alerts for validator downtime, missed proposals
- [ ] Log aggregation (Loki/ELK)
- [ ] 24/7 on-call rotation established

#### Operations

- [ ] Backup/restore tested monthly
- [ ] Incident response playbook documented
- [ ] Upgrade process tested on staging
- [ ] Team trained on emergency procedures

#### Compliance

- [ ] Legal review complete
- [ ] Smart contract audits (if applicable)
- [ ] Penetration test passed
- [ ] Terms of service published

---

## Example Production Config (Besu)

```bash
#!/bin/bash
# Start Besu validator in production mode

besu \
  --data-path=/data/besu/validator-1 \
  --genesis-file=/config/genesis.json \
  --network-id=7777 \
  --p2p-host=10.0.1.10 \
  --p2p-port=30303 \
  --rpc-http-enabled=false \                # No RPC on validators
  --rpc-ws-enabled=false \
  --engine-jwt-secret=/secure/jwt-secret.hex \
  --engine-host-allowlist=localhost \
  --host-allowlist=localhost \
  --bootnodes=enode://abc123@10.0.1.11:30303,enode://def456@10.0.1.12:30303 \
  --logging=JSON \
  --metrics-enabled=true \
  --metrics-host=0.0.0.0 \
  --metrics-port=9545 \
  --max-peers=25 \
  --sync-mode=FAST \
  --pruning-enabled=true
```

---

## Resources

- **Besu Docs**: https://besu.hyperledger.org/
- **Polygon-Edge Docs**: https://docs.polygon.technology/edge/
- **CIS Benchmarks**: https://www.cisecurity.org/cis-benchmarks/
- **OWASP**: https://owasp.org/www-project-blockchain-security/

---

**Remember**: Security is a process, not a product. Stay vigilant. 🔒
