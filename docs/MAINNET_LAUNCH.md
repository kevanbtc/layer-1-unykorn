# 🚀 Unykorn L1 Mainnet Launch Guide

**CRITICAL**: This guide walks you through launching your sovereign Layer-1 blockchain to production mainnet. Follow every step carefully.

---

## 📋 Pre-Launch Checklist (Complete ALL Items)

### Phase 1: Security & Keys (Week 1-2)

- [ ] **Generate validator keys on air-gapped machine**
  - Use offline computer (no network connection)
  - Run: `.\scripts\production-setup.ps1 -GenerateKeys`
  - Export keys to encrypted USB drive
  - **NEVER** connect air-gapped machine to internet after key generation

- [ ] **Secure key backup (3-2-1 rule)**
  - 3 copies minimum
  - 2 different storage types (USB + encrypted cloud)
  - 1 off-site location (bank safe deposit box, different geographic region)
  - Test restoration process

- [ ] **Create production genesis configuration**
  - Edit `production/genesis-template.json`
  - Replace treasury addresses (NOT dev addresses!)
  - Set initial token allocation
  - Configure QBFT parameters (2s block time, 30000 epoch length)
  - Add validator addresses to `extraData` field

- [ ] **Generate JWT secret for Engine API**
  - Run: `.\scripts\production-setup.ps1`
  - Store `production/jwt-secret.hex` securely
  - Distribute to all validator nodes via secure channel (not email!)

### Phase 2: Infrastructure Setup (Week 2-3)

- [ ] **Domain & DNS**
  - Register domain (e.g., `unykorn.com`)
  - Create DNS records:
    - `rpc.unykorn.com` → ALB DNS
    - `explorer.unykorn.com` → Blockscout
    - `grafana.unykorn.com` → Grafana dashboard

- [ ] **SSL Certificates**
  - Request certificate in AWS Certificate Manager (ACM)
  - Validate domain ownership (DNS or email validation)
  - Note ARN for Terraform config

- [ ] **Cloud Infrastructure (Terraform)**
  ```bash
  cd terraform
  
  # Initialize Terraform
  terraform init
  
  # Review plan
  terraform plan
  
  # Apply (creates VPC, subnets, security groups, EC2 instances)
  terraform apply
  
  # Save outputs
  terraform output > ../production/terraform-outputs.txt
  ```

- [ ] **Firewall Rules**
  - Validators: ONLY private subnet access
  - Sentries: Public P2P (30303), RPC via ALB only
  - Monitoring: Restrict Grafana to your IP
  - SSH: Restrict to your IP or VPN

- [ ] **Instance Hardening**
  - Update all packages: `apt update && apt upgrade -y`
  - Install fail2ban: `apt install fail2ban`
  - Disable root SSH login
  - Enable unattended security updates
  - Configure firewall (ufw or iptables)

### Phase 3: Validator Deployment (Week 3-4)

- [ ] **Deploy validator nodes**
  - SSH to each validator instance
  - Copy validator keys to `/data/validator-N/`
  - Copy genesis.json to `/genesis/genesis.json`
  - Copy jwt-secret.hex to `/secrets/jwt-secret.hex`
  - Set file permissions: `chmod 600 /data/validator-*/key`

- [ ] **Start validators in sequence**
  ```bash
  # Validator 0 (bootnode) first
  docker-compose -f production/docker-compose.production.yml up -d validator-0
  
  # Wait 30 seconds, then start others
  docker-compose -f production/docker-compose.production.yml up -d validator-1 validator-2 validator-3
  ```

- [ ] **Verify consensus**
  ```bash
  # Check logs for block production
  docker logs -f unykorn-validator-0
  
  # Look for: "Imported new chain segment"
  # Block numbers should increase every 2 seconds
  ```

- [ ] **Verify validator connectivity**
  ```bash
  # Check peer count (should be 3+ for 4-validator setup)
  curl -X POST http://localhost:9545/metrics | grep besu_peers_connected_total
  ```

### Phase 4: Sentry & RPC Deployment (Week 4)

- [ ] **Deploy sentry nodes**
  - SSH to sentry instances
  - Copy genesis.json
  - Start sentries: `docker-compose -f production/docker-compose.production.yml up -d sentry-0 sentry-1`

- [ ] **Verify sentry sync**
  ```bash
  # Check block height matches validators
  curl -X POST https://rpc.unykorn.com \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
  ```

- [ ] **Test RPC endpoints**
  ```bash
  # Chain ID
  curl -X POST https://rpc.unykorn.com \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
  
  # Should return: {"jsonrpc":"2.0","id":1,"result":"0x1e61"}  # 7777 in hex
  
  # Latest block
  curl -X POST https://rpc.unykorn.com \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
  
  # Get balance (test premine)
  curl -X POST https://rpc.unykorn.com \
    -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xYOUR_TREASURY_ADDRESS","latest"],"id":1}'
  ```

### Phase 5: Monitoring & Observability (Week 4-5)

- [ ] **Deploy Prometheus + Grafana**
  ```bash
  docker-compose -f production/docker-compose.production.yml up -d prometheus grafana
  ```

- [ ] **Configure Grafana dashboards**
  - Access: `https://grafana.unykorn.com`
  - Default login: `admin` / `CHANGE_ME_IN_PRODUCTION`
  - **IMMEDIATELY** change admin password!
  - Import Besu dashboard: ID 16485 from Grafana.com
  - Verify metrics: Block height, peer count, gas used

- [ ] **Test alert rules**
  - Stop one validator temporarily
  - Verify alert fires within 2 minutes
  - Set up email notifications (SMTP or SNS)

- [ ] **Deploy Blockscout explorer**
  ```bash
  docker-compose -f production/docker-compose.production.yml up -d postgres blockscout
  ```

- [ ] **Verify Blockscout**
  - Access: `https://explorer.unykorn.com`
  - Search for genesis block (0)
  - Verify validator addresses shown
  - Check latest blocks updating

### Phase 6: Security Audit (Week 5-6)

- [ ] **Penetration testing**
  - Hire security firm OR use tools:
    - `nmap` - Port scanning
    - `testssl.sh` - SSL/TLS audit
    - `lynis` - System hardening audit

- [ ] **Smart contract audits** (if deploying governance/bridge contracts)
  - Trail of Bits, OpenZeppelin, or Quantstamp
  - Budget: $20k-$50k minimum
  - Timeline: 4-6 weeks

- [ ] **Review production security checklist**
  - Read `docs/PRODUCTION_SECURITY.md` thoroughly
  - Verify ALL items completed
  - Document exceptions with justification

- [ ] **Incident response plan**
  - Define escalation procedures
  - Document emergency contacts
  - Create runbooks for common scenarios:
    - Validator down
    - DDoS attack
    - Critical bug discovered
  - Test incident response (tabletop exercise)

### Phase 7: Public Launch (Week 6-7)

- [ ] **Soft launch (invite-only testnet)**
  - Deploy to testnet infrastructure first
  - Invite 10-20 trusted users
  - Run for 2+ weeks
  - Monitor for issues

- [ ] **Mainnet genesis countdown**
  - Announce launch date (2 weeks in advance minimum)
  - Publish genesis file publicly
  - Provide MetaMask network JSON
  - Create public documentation

- [ ] **Launch day execution**
  ```bash
  # Final checks
  - All validators online? ✓
  - Sentries synced? ✓
  - Monitoring active? ✓
  - Backups tested? ✓
  - Team on standby? ✓
  
  # Start block production (all validators up)
  # Monitor for first 24 hours continuously
  ```

- [ ] **Post-launch monitoring (first 72 hours)**
  - 24/7 on-call coverage
  - Monitor Grafana dashboards
  - Watch for unusual activity
  - Be prepared to halt chain if critical bug found

### Phase 8: Ongoing Operations

- [ ] **Weekly tasks**
  - Review metrics (block time, missed proposals)
  - Check disk space (expand if >70% full)
  - Verify backups completed successfully
  - Update documentation

- [ ] **Monthly tasks**
  - Security updates (coordinate validator upgrades)
  - Review logs for anomalies
  - Test disaster recovery procedures
  - Rotate access keys/passwords

- [ ] **Quarterly tasks**
  - Security audit refresh
  - Capacity planning (disk, compute, network)
  - Review and update incident response plan
  - Team training/tabletop exercises

---

## 🔐 Security Verification Matrix

| Item | Status | Verified By | Date |
|------|--------|-------------|------|
| Validator keys generated offline | ⬜ | | |
| Keys backed up to 3 locations | ⬜ | | |
| JWT secret rotated | ⬜ | | |
| Firewall rules tested | ⬜ | | |
| SSL certificates valid | ⬜ | | |
| Monitoring alerts firing | ⬜ | | |
| Backups tested (restoration) | ⬜ | | |
| Incident response plan documented | ⬜ | | |
| Team trained on procedures | ⬜ | | |
| Legal/compliance review complete | ⬜ | | |

---

## 📊 Launch Day Metrics to Monitor

```
CRITICAL Metrics (check every 5 minutes for first 24h):
- Block height increasing (every 2 seconds)
- All validators online (4/4 up)
- Peer count stable (>3 per validator)
- No missed block proposals
- RPC response time <100ms
- No chain reorgs (MUST be 0 in QBFT!)

WARNING Metrics (check hourly):
- Disk usage <70%
- Memory usage <80%
- CPU usage <75%
- Network errors <1/sec
- RPC request rate (plan for scaling if >500 req/s)
```

---

## 🚨 Emergency Procedures

### Validator Compromised

1. **IMMEDIATELY** isolate validator (firewall block all traffic)
2. Stop validator container
3. Notify other validator operators
4. Generate new validator keys offline
5. Update genesis if needed (requires coordination)
6. Restore from backup to clean instance
7. Post-mortem analysis

### Critical Bug Discovered

1. **HALT** block production (coordinate with all validators)
2. Notify community immediately (Discord, Twitter, etc.)
3. Assess impact and develop fix
4. Test fix on staging network
5. Coordinate simultaneous upgrade
6. Resume block production
7. Publish post-mortem

### DDoS Attack

1. Enable CloudFlare "Under Attack" mode
2. Scale sentry nodes horizontally (add more via Terraform)
3. Tighten rate limits (10 req/s → 5 req/s)
4. Block attacking IP ranges at firewall
5. Contact CloudFlare/AWS Shield support

---

## 📞 Launch Team Roles

| Role | Responsibility | On-Call |
|------|----------------|---------|
| **Lead Validator Operator** | Coordinate validator upgrades | 24/7 for first week |
| **DevOps Engineer** | Monitor infrastructure, scaling | 24/7 for first week |
| **Security Lead** | Monitor for attacks, audit logs | On-call |
| **Community Manager** | Public communication, support | Business hours + emergencies |
| **Smart Contract Dev** | Deploy/verify contracts | On-call |

---

## ✅ Final Go/No-Go Decision (T-24 hours)

**ALL must be YES to proceed with launch:**

- [ ] All validators successfully producing blocks on testnet?
- [ ] Security audit completed with no critical findings?
- [ ] Monitoring and alerting fully operational?
- [ ] Backups tested and verified?
- [ ] Incident response team briefed and on standby?
- [ ] Legal/compliance requirements met?
- [ ] Public documentation published?
- [ ] Community notified of launch time?

**If ANY item is NO, DELAY launch until resolved.**

---

## 🎉 Post-Launch

After successful mainnet launch:

1. **Week 1**: Continuous monitoring, daily team check-ins
2. **Week 2**: Start onboarding users, deploy initial dApps
3. **Month 1**: Publish metrics dashboard publicly
4. **Month 3**: First network upgrade (test upgrade process)
5. **Month 6**: Security audit refresh
6. **Year 1**: Plan for decentralization (if applicable)

---

## 📚 Additional Resources

- **Besu Documentation**: <https://besu.hyperledger.org/>
- **QBFT Consensus**: <https://besu.hyperledger.org/stable/private-networks/how-to/configure/consensus/qbft>
- **AWS Well-Architected Framework**: <https://aws.amazon.com/architecture/well-architected/>
- **OWASP Blockchain Security**: <https://owasp.org/www-project-blockchain-security/>

---

**YOU OWN THIS LAYER-1. Launch with confidence, monitor relentlessly, respond decisively.** 🔥

*"In blockchain, trust is earned block by block."*
