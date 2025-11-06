# Security Policy

## 🔒 Reporting a Vulnerability

The Unykorn L1 team takes security seriously. We appreciate your efforts to responsibly disclose your findings.

### Private Disclosure (Preferred)

For **critical vulnerabilities** that could impact the security of the network, user funds, or sensitive data:

1. **Do NOT** create a public GitHub issue
2. **Use GitHub Security Advisories**: Navigate to the repository → Security → Advisories → "Report a vulnerability"
3. **Or email**: [INSERT SECURITY EMAIL] with subject "SECURITY: [Brief Description]"

We will acknowledge receipt within 48 hours and provide a detailed response within 7 days.

### Public Disclosure

For **non-critical security concerns** (documentation issues, minor configuration improvements):

1. Create a GitHub issue using the "Security Vulnerability" template
2. Label it with `security` and `low-priority`

## 🎯 Scope

### In Scope

The following components are within scope for security reports:

- ✅ Smart contracts in `/contracts` directory
- ✅ Consensus mechanism and validator security
- ✅ RPC endpoint authentication and authorization
- ✅ Docker and infrastructure configurations
- ✅ Key generation and management scripts
- ✅ Deployment automation (Terraform, scripts)
- ✅ Dependencies and third-party libraries
- ✅ Documentation that could lead to security issues

### Out of Scope

The following are **not** considered security vulnerabilities:

- ❌ Issues in development-only accounts (`secrets/DEV_ONLY_accounts.json`)
- ❌ Known limitations documented in `PRODUCTION_SECURITY.md`
- ❌ Theoretical attacks requiring >51% validator control
- ❌ Social engineering attacks (phishing, etc.)
- ❌ Issues requiring physical access to validator servers
- ❌ Denial of service requiring excessive computational resources
- ❌ Issues in third-party dependencies with no path to exploitation

## 🏆 Bug Bounty Program

### Reward Tiers

| Severity | Description | Reward |
|----------|-------------|--------|
| **Critical** | Complete network compromise, unlimited fund theft, validator key exposure | $10,000 - $50,000 |
| **High** | Limited fund theft, consensus disruption, RPC compromise | $2,500 - $10,000 |
| **Medium** | Information disclosure, DoS with moderate impact, configuration issues | $500 - $2,500 |
| **Low** | Best practice violations, minor configuration issues | $100 - $500 |

### Eligibility

To be eligible for a bug bounty reward:

- ✅ You must be the first to report the vulnerability
- ✅ The vulnerability must be reproducible and have clear impact
- ✅ You must follow responsible disclosure practices
- ✅ You must not exploit the vulnerability for personal gain
- ✅ You must not publicly disclose the vulnerability before it's fixed
- ✅ You must provide sufficient detail for us to reproduce and fix

### Payment

Rewards are paid in:
- **Cryptocurrency**: UNY tokens or stablecoins (USDC/DAI)
- **Fiat**: USD via wire transfer (for amounts >$1,000)

## 🛡️ Security Best Practices

### For Developers

1. **Smart Contract Security**
   - Follow [Consensys Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
   - Use latest OpenZeppelin contracts
   - Test with Slither, Mythril, and Echidna
   - Conduct formal verification for critical contracts
   - Add NatSpec comments for security-relevant code

2. **Key Management**
   - Never commit private keys to version control
   - Use hardware wallets for production deployments
   - Generate keys on air-gapped systems
   - Follow 3-2-1 backup rule for validator keys
   - Rotate JWT secrets quarterly

3. **Code Review**
   - All PRs require review from 2+ maintainers
   - Security-sensitive PRs require review from security team
   - Use GitHub code scanning and Dependabot
   - Run automated tests before merging

### For Operators

1. **Validator Security**
   - Run validators in private subnets (no public internet)
   - Use sentry nodes for P2P networking
   - Enable firewall rules (allow only necessary ports)
   - Monitor validator health 24/7
   - Keep Besu version up-to-date

2. **Infrastructure Security**
   - Enable 2FA on all cloud provider accounts
   - Use IAM roles with least privilege
   - Encrypt data at rest and in transit
   - Regular security audits and penetration testing
   - Maintain audit logs for all access

3. **Incident Response**
   - Have incident response plan documented
   - Regular backup and restore testing
   - Communication plan for security incidents
   - Post-mortem analysis after incidents

## 🔍 Security Audits

### Completed Audits

| Date | Auditor | Scope | Report |
|------|---------|-------|--------|
| TBD | [Auditor Name] | Smart Contracts | [Link] |
| TBD | [Auditor Name] | Infrastructure | [Link] |

### Planned Audits

- **Q1 2025**: Smart contract security audit (Consensys Diligence or Trail of Bits)
- **Q2 2025**: Infrastructure penetration testing
- **Q3 2025**: Consensus mechanism formal verification

## 📋 Security Checklist

Before deploying to production, ensure:

### Smart Contracts
- [ ] Audited by reputable third party
- [ ] Unit tests with >95% coverage
- [ ] Fuzz tested with Echidna
- [ ] Static analysis with Slither (no critical/high issues)
- [ ] Gas optimization completed
- [ ] Emergency pause mechanisms implemented
- [ ] Upgrade mechanisms secured (if applicable)
- [ ] Access controls properly configured

### Infrastructure
- [ ] Validators running latest Besu version
- [ ] Private keys generated on air-gapped hardware
- [ ] Keys backed up to 3 locations (encrypted)
- [ ] Firewall rules configured (restrictive)
- [ ] Monitoring and alerting operational
- [ ] DDoS protection enabled
- [ ] TLS/SSL certificates valid
- [ ] Regular backups automated and tested

### Operational Security
- [ ] Incident response plan documented
- [ ] On-call rotation established
- [ ] Communication channels secured
- [ ] Access controls reviewed and minimized
- [ ] Security audit reports addressed
- [ ] Compliance requirements met
- [ ] Insurance coverage obtained (if applicable)

## 🚨 Vulnerability Disclosure Timeline

1. **Day 0**: Vulnerability reported to security team
2. **Day 1-2**: Security team acknowledges and begins investigation
3. **Day 3-7**: Security team validates and assesses severity
4. **Day 7-30**: Development team creates fix and tests
5. **Day 30-60**: Fix deployed to testnet → mainnet
6. **Day 60-90**: Public disclosure with credit to reporter
7. **Day 90+**: Bug bounty paid (if applicable)

## 📞 Contact Information

- **Security Email**: [INSERT SECURITY EMAIL]
- **GitHub Security Advisories**: [Repository Security Tab]
- **PGP Key**: [Link to PGP public key]
- **Emergency Contact**: [INSERT PHONE/PAGER]

## 📜 Security Hall of Fame

We recognize and thank the following security researchers for their responsible disclosure:

| Researcher | Vulnerability | Severity | Date |
|------------|--------------|----------|------|
| TBD | TBD | TBD | TBD |

---

## 🔗 Additional Resources

- [PRODUCTION_SECURITY.md](docs/PRODUCTION_SECURITY.md) - Operational security guide
- [Ethereum Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)

---

**Remember**: Security is everyone's responsibility. When in doubt, report it. 🛡️
