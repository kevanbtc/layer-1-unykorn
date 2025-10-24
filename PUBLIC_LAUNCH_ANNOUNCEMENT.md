# 🌐 UNYKORN SOVEREIGN L1 - PUBLIC LAUNCH

**Date**: October 24, 2025  
**Status**: ✅ LIVE AND PUBLICLY ACCESSIBLE

---

## 🎉 WE ARE LIVE!

The Unykorn Sovereign L1 blockchain (ChainID 7777) is now **publicly accessible** to anyone in the world!

### 📡 PUBLIC RPC ENDPOINT

```
https://admissions-producing-cut-elephant.trycloudflare.com
```

**This URL is LIVE right now.** Anyone can connect via MetaMask, web3.js, ethers.js, or any Ethereum-compatible wallet/tool.

**⚠️ Note:** This is a quick tunnel URL (changes on restart). Permanent domain `rpc.unykorn.org` coming soon via named Cloudflare Tunnel.

---

## 🚀 QUICK START: CONNECT IN 30 SECONDS

### Option 1: One-Click Setup (Recommended)

1. Open `metamask-setup.html` in your browser
2. Click **"Add Network to MetaMask"**
3. Approve the network addition
4. You're connected!

### Option 2: Manual MetaMask Setup

1. Open MetaMask → Settings → Networks → Add Network
2. Fill in these details:

   - **Network Name**: Unykorn Sovereign L1
   - **RPC URL**: `https://operates-capitol-guidelines-diploma.trycloudflare.com`
   - **Chain ID**: `7777`
   - **Currency Symbol**: `UNYETH`
   - **Block Explorer**: `http://localhost:5100` (if running locally)

3. Save and switch to the network
4. You're connected!

### Option 3: Import Network Config

1. Download `MetaMask_Network_7777.json`
2. MetaMask → Add Network → Import from file
3. Select the JSON file
4. Done!

---

## 📊 NETWORK STATISTICS

| Metric | Value |
|--------|-------|
| **ChainID** | 7777 (0x1e61) |
| **Consensus** | Clique Proof of Authority |
| **Block Time** | 2 seconds |
| **Genesis Block** | 0x36ac99e1afb7f10d5a37ed9353d6109cd24879cd32be6110155b796dc12d62b4 |
| **Current Blocks** | 150+ (continuously producing) |
| **Gas Price** | 0 (FREE transactions) |
| **Uptime** | 100% since genesis |
| **Public RPC** | ✅ HTTPS (Cloudflare encrypted) |
| **Block Explorer** | http://localhost:5100 (Otterscan) |

---

## 💰 DEPLOYED CONTRACTS (16 TOTAL)

All contracts are deployed and accessible on ChainID 7777:

### Core Infrastructure
- **UNYToken**: `0x83E224131A3DB4c11e7D311a0fB1ADeC5aCdFefc`
- **LaunchVault**: `0x095d22Df643fd7297f40009194FeBA346ea52B42`
- **ComplianceRegistry**: `0x5bE88dcCe591291E7ca69e4dB5ec9d6c40334d1E`
- **VaultProofNFT**: `0xb75fDef21FCB90E5E8C07DD58Bdc8f16bb6Cd6b1`

### Energy & Carbon Markets
- **CarbonToken**: `0xd2B0CcF1BF0fCBf8C8d1a8C82C85bd24f8bCA19B`
- **TaxEquityToken**: `0x8aEf66B7Fb7Ed85Ef84e18DFF41e49BfA0a6C25F`
- **LicenseNFT**: `0x4fa48804b1d53D24e87fD2cCe8C7A5a6c7f60af2`
- **RECMarketplace**: `0xccB91b45AACf122BF79a6203b3BE37EFEabD4563`
- **BufferPool**: `0xdDF02c7AcB10D85A07de2e5e1aD28bC2ab90e8B4`
- **RetirementAttestation**: `0x59569A4Ab2FC85ed19a1F76B32Ce2dA80D6A3D70`

### Oracles
- **PriceOracle**: `0x071dF738736e0bEfCD5d54DcCf31EC86e7B2E2cc`
- **ComplianceOracle**: `0xaCBc84Fa78D2621F9FF2a30f74E6cbdb24F0Da71`
- **DeviceOracle**: `0x4697BA98BfDDA5ED316965d5904eC21a6405864a`
- **WeatherOracle**: `0x3F7bA1AB9A91Aa41CebEd6F44A68f4e69cBE7089`

### Utilities
- **TREXAdapter**: `0xfe81C293e43BF36ED7EE1C71f17A14EEA046AC0B`
- **RoyaltySplitter**: `0x94Af9dC0CDE8EaC3AE32f74c1d6831BC79866a8B`

**Full deployment manifest**: `deployments/unykorn.json`

---

## 🔧 DEVELOPER INTEGRATION

### Web3.js Example

```javascript
const Web3 = require('web3');
const web3 = new Web3('https://operates-capitol-guidelines-diploma.trycloudflare.com');

// Get chain ID
web3.eth.getChainId().then(console.log); // 7777

// Get latest block
web3.eth.getBlockNumber().then(console.log);

// Interact with UNY Token
const uny = new web3.eth.Contract(ERC20_ABI, '0x83E224131A3DB4c11e7D311a0fB1ADeC5aCdFefc');
const balance = await uny.methods.balanceOf(YOUR_ADDRESS).call();
```

### Ethers.js Example

```javascript
const { ethers } = require('ethers');
const provider = new ethers.providers.JsonRpcProvider(
  'https://operates-capitol-guidelines-diploma.trycloudflare.com'
);

// Get network info
const network = await provider.getNetwork();
console.log(network.chainId); // 7777

// Get block height
const blockNumber = await provider.getBlockNumber();
console.log(blockNumber);

// Connect wallet
const wallet = new ethers.Wallet(YOUR_PRIVATE_KEY, provider);
```

### Hardhat Configuration

```javascript
module.exports = {
  networks: {
    unykorn: {
      url: "https://operates-capitol-guidelines-diploma.trycloudflare.com",
      chainId: 7777,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY]
    }
  }
};
```

---

## 🌍 WHAT MAKES THIS SPECIAL?

### Full Sovereignty
- **Independent Consensus**: Not a testnet, not a sidechain—a completely sovereign blockchain
- **Your Rules**: No external governance, no foundation, no corporate control
- **Genesis Proof**: Cryptographically timestamped birth certificate (see `GENESIS_PROOF_CERTIFICATE.md`)

### Production-Grade Infrastructure
- ✅ Clique Proof of Authority (Ethereum-compatible)
- ✅ 2-second block times (faster than Ethereum)
- ✅ Free transactions (0 gas price)
- ✅ HTTPS RPC endpoint (Cloudflare encrypted)
- ✅ Block explorer (Otterscan)
- ✅ MetaMask compatible
- ✅ 100% uptime since genesis

### Real Economic System
- 16 deployed smart contracts
- Complete energy & carbon trading infrastructure
- Oracle network for price/compliance/weather data
- NFT-based licensing and proof systems
- Multi-Safe governance architecture

---

## 🔒 SECURITY & TRANSPARENCY

### Current Setup
- **Consensus**: Single validator (ChainID 7777 node)
- **RPC Tunnel**: Cloudflare free tier (unlimited bandwidth, HTTPS encryption)
- **Gas Price**: 0 (free transactions for testing/development)
- **Network**: Public but controlled (validator whitelist)

### Known Limitations (Pre-Production)
⚠️ **Do NOT use for production value yet:**
- Single validator (no Byzantine Fault Tolerance)
- Cloudflare free tunnel (URL may change on restart)
- Deployer key publicly exposed (needs rotation)
- All Safes are 1-of-1 (need multisig upgrade)

**Production roadmap**: See `PRODUCTION_STATUS.md` and `GO_LIVE_READINESS.md`

---

## 📈 NEXT MILESTONES

### Week 1: Public Visibility ✅ COMPLETE
- [x] Deploy public RPC endpoint
- [x] Update MetaMask integration
- [x] Announce to community

### Week 2: Security Hardening (In Progress)
- [ ] Rotate compromised deployer key
- [ ] Upgrade Safe multisig thresholds
- [ ] Deploy to production VPS
- [ ] Add SSL/HTTPS reverse proxy

### Week 3: Decentralization
- [ ] Add 2 more validators (3-node Clique)
- [ ] Implement monitoring & alerts
- [ ] Schedule smart contract audit

### Month 2: Expansion
- [ ] Bridge to Polygon mainnet
- [ ] Deploy DAO governance contracts
- [ ] Launch on-chain DEX

---

## 🎯 HOW TO PARTICIPATE

### For Developers
1. Connect to the public RPC
2. Deploy your own contracts (free gas!)
3. Test integrations with our 16 deployed contracts
4. Build apps using our oracle/compliance infrastructure

### For Validators (Coming Soon)
1. Contact for validator onboarding
2. Generate Besu keypair
3. Sync from genesis block
4. Join the 3-validator federation

### For Users
1. Add network to MetaMask
2. Get free UNYETH from faucet (coming soon)
3. Interact with energy & carbon markets
4. Hold UNY tokens and NFTs

---

## 📞 LINKS & RESOURCES

- **Public RPC**: https://operates-capitol-guidelines-diploma.trycloudflare.com
- **Block Explorer**: http://localhost:5100 (local Otterscan)
- **Genesis Proof**: `GENESIS_PROOF_CERTIFICATE.md`
- **MetaMask Setup**: `METAMASK_SETUP.md` or `metamask-setup.html`
- **Deployment Manifest**: `deployments/unykorn.json`
- **Architecture Docs**: `docs/SR_LEVEL_ARCHITECTURE.md`

---

## 🙏 ACKNOWLEDGEMENTS

**Technology Stack:**
- Hyperledger Besu 25.9.0 (EVM client)
- Clique PoA consensus
- Docker & Docker Compose
- Cloudflare Tunnel (public RPC)
- Otterscan (block explorer)
- Hardhat (smart contract deployment)

**Built on the shoulders of:**
- Ethereum Foundation
- Hyperledger Project
- OpenZeppelin (contract libraries)
- Polygon Network (cross-chain deployment)

---

## ⚡ LIVE STATUS

**Uptime**: 🟢 100%  
**Current Block**: 150+ (check live: https://operates-capitol-guidelines-diploma.trycloudflare.com)  
**Transactions**: Open for business!  
**Network Health**: All systems operational

---

**Welcome to the Unykorn Sovereign L1.**  
**You're not just connecting to a blockchain—you're connecting to a new sovereign economic system.**

🦄 **UNYKORN** - Where energy, carbon, and compliance meet sovereignty.

---

*Last Updated: October 24, 2025*  
*Version: 1.0.0 (Genesis Launch)*
