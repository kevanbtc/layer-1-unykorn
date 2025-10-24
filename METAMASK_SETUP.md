# 🦊 MetaMask & Wallet Integration Guide

## Unykorn Sovereign L1 (ChainID 7777)

**Status**: ✅ LIVE - Producing blocks every 2 seconds  
**Deployment Block**: 20  
**Total Contracts**: 16  
**Consensus**: Clique PoA  

---

## 🌐 Network Configuration

### Quick Add to MetaMask

**Option 1: Manual Entry**
1. Open MetaMask
2. Click network dropdown → "Add Network" → "Add network manually"
3. Enter the following:

```
Network Name: Unykorn Sovereign L1
RPC URL: http://127.0.0.1:8555
Chain ID: 7777
Currency Symbol: UNYETH
Block Explorer: (none - local only)
```

**Option 2: Import JSON** (see `MetaMask_Network_7777.json`)

---

## 📋 Deployed Contract Addresses (ChainID 7777)

### Core Tokens
- **UNYToken**: `0x83E224131A3DB4c11e7D311a0fB1ADeC5aCdFefc`
- **CarbonToken**: `0xCfa349b5149Ec607C4A5C96Bd16a99bb67259Ddc`
- **TaxEquityToken**: `0x04258006d540C163795Da896D8d7D0b1BA7c3B58`

### Vaults & NFTs
- **LaunchVault**: `0x095d22Df643fd7297f40009194FeBA346ea52B42`
- **VaultProofNFT**: `0x7740a1abA4792314199EF4a616da626C1459029D`
- **LicenseNFT**: `0x6dfeEDAD2dD83D556F64E3FeE59ecCcB963CD0dB`

### Oracles
- **DeviceOracle** (PriceOracle): `0x4697BA98BfDDA5ED316965d5904eC21a6405864a`
- **ComplianceOracle**: `0x2F0ca69374652f712466e991EAEE0b92a80C42C7`
- **WeatherOracle**: `0x01A2aDe3D339097300B53f9Db83c1852F6412088`

### Marketplaces
- **RECMarketplace**: `0xccB91b45AACf122BF79a6203b3BE37EFEabD4563`
- **BufferPool**: `0x86473e23E6F44766dc3063B4A0cac8Cf3035D6c4`

### Compliance & Retirement
- **ComplianceRegistry**: `0x57fc2850F71AbA6d48491287531F9a5eca1050cc`
- **RetirementAttestation**: `0x9FcEA87a13adf747Ad9c225aa7AC8D75683094e1`
- **TREXAdapter (ERC1400)**: `0x31fDA153Ce08a56461945Be6264F25C47CF2e0A9`

### Fee & Royalty
- **RoyaltySplitter**: `0x09B742c644Ce6499DE68bdBf1c38F1347A4abc7c`
- **FeeRouter**: `0x64d9f3f95478BCf196a2C546Db3fBD4E0f18aD58`

---

## 🔑 Pre-Funded Accounts

### Deployer Account (Genesis Allocation)
- **Address**: `0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB`
- **Balance**: ~10^60 UNYETH (unlimited for testing)
- **Private Key**: `0x7b2b32f0d6f78140c8803bec4469978d9737d9bb458e95cef8c85bb912520b55`
  - ⚠️ **WARNING**: This key is compromised (publicly exposed). DO NOT use for production!
  - ✅ **Safe for local testing only**

### Validator Account
- **Address**: `0xa32a4c8d458783a1b2537f8446f6e0b978a530aa`
- **Balance**: ~10^60 UNYETH
- **Role**: Clique block sealer

---

## 🛠️ Adding UNY Token to MetaMask

1. Connect to Unykorn Sovereign L1 network
2. Click "Import tokens"
3. Enter:
   - **Token Contract Address**: `0x83E224131A3DB4c11e7D311a0fB1ADeC5aCdFefc`
   - **Token Symbol**: `UNY`
   - **Token Decimals**: `18`

You should see your UNY balance (1 billion tokens at deployer address).

---

## 🌍 Public Access (Make it Available to Others)

### Current State: LOCAL ONLY
- RPC: `http://127.0.0.1:8555` (only accessible from your machine)
- Port 8555 listening on localhost

### To Make PUBLIC (Internet Access):

#### Option 1: ngrok (Quick & Easy)
```bash
# Install ngrok: https://ngrok.com/download
ngrok http 8555
```
You'll get a public URL like: `https://abc123.ngrok.io`
- Share this URL as the RPC endpoint
- ⚠️ Free tier has limits, URL changes on restart

#### Option 2: Cloudflare Tunnel (Free & Permanent)
```bash
# Install cloudflared
cloudflared tunnel --url http://localhost:8555
```
- Free permanent subdomain
- Better for production
- Handles SSL/TLS automatically

#### Option 3: VPS/Cloud Deployment (Production)
Deploy Besu validator to:
- **AWS EC2** / Azure VM / Google Cloud
- **DigitalOcean** Droplet ($4/mo)
- **Linode** / **Vultr**

Configure security group to allow:
- Port 8545 (HTTP RPC)
- Port 8546 (WebSocket)
- Port 30303 (P2P discovery)

Then update RPC URL to: `http://<your-ip>:8545`

---

## 📱 Mobile Wallet Support

### MetaMask Mobile
1. Open app → Settings → Networks → Add Network
2. Use **public RPC URL** (from ngrok/cloudflare/VPS above)
3. Same network config as desktop

### Trust Wallet
1. Settings → Networks → Add Custom Network
2. Enter same details as MetaMask

### WalletConnect
- Once you have public RPC, any WalletConnect-compatible wallet can connect
- QR code scanning works automatically

---

## 🔗 Web3 Integration (For Your DApp)

### JavaScript/TypeScript (ethers.js)
```javascript
import { ethers } from 'ethers';

// Connect to Sovereign L1
const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8555');
// OR for public: 'https://your-public-url.ngrok.io'

// ChainID verification
const network = await provider.getNetwork();
console.log(network.chainId); // 7777n

// Contract instance
const unyToken = new ethers.Contract(
  '0x83E224131A3DB4c11e7D311a0fB1ADeC5aCdFefc',
  unyTokenABI,
  provider
);

// Read balance
const balance = await unyToken.balanceOf('0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB');
console.log(ethers.formatEther(balance)); // 1000000000.0 UNY
```

### Web3.js
```javascript
import Web3 from 'web3';

const web3 = new Web3('http://127.0.0.1:8555');

// ChainID
const chainId = await web3.eth.getChainId();
console.log(chainId); // 7777

// Get block number
const block = await web3.eth.getBlockNumber();
console.log(block); // Current block height
```

### wagmi (React)
```typescript
import { createConfig, http } from 'wagmi';
import { defineChain } from 'viem';

export const unykornSovereign = defineChain({
  id: 7777,
  name: 'Unykorn Sovereign L1',
  nativeCurrency: {
    decimals: 18,
    name: 'UNYETH',
    symbol: 'UNYETH',
  },
  rpcUrls: {
    default: { http: ['http://127.0.0.1:8555'] },
    public: { http: ['http://127.0.0.1:8555'] },
  },
});

const config = createConfig({
  chains: [unykornSovereign],
  transports: {
    [unykornSovereign.id]: http(),
  },
});
```

---

## 🎯 Next Level Features to Build

### 1. Block Explorer (Essential)
**Option A: Blockscout (Open Source)**
```bash
# Docker deployment
git clone https://github.com/blockscout/blockscout.git
cd blockscout/docker-compose
# Edit common-blockscout.env:
#   ETHEREUM_JSONRPC_HTTP_URL=http://host.docker.internal:8555
#   CHAIN_ID=7777
docker-compose up -d
```
Access at: `http://localhost:4000`

**Option B: Otterscan (Lightweight)**
```bash
docker run --rm -p 5100:80 \
  -e ERIGON_URL=http://host.docker.internal:8555 \
  otterscan/otterscan:latest
```

### 2. Faucet (For Testnet/Demo Users)
Create a simple faucet that drips UNYETH to users:
```javascript
// faucet.js - Express server
app.post('/faucet/:address', async (req, res) => {
  const wallet = new ethers.Wallet(FAUCET_KEY, provider);
  const tx = await wallet.sendTransaction({
    to: req.params.address,
    value: ethers.parseEther('10'), // 10 UNYETH
  });
  res.json({ txHash: tx.hash });
});
```

### 3. Chain Registry Entry
Submit to **ChainList** (https://chainlist.org):
- Users can auto-add your network with 1 click
- Requires public RPC endpoint
- JSON config at: https://github.com/ethereum-lists/chains

### 4. Multi-Validator Setup (Decentralization)
Add 2 more validators for Byzantine Fault Tolerance:
```yaml
# docker-compose.yml
validator-2:
  # Same config, different ports & keys
validator-3:
  # Clique requires odd number (1, 3, 5, etc.)
```

### 5. Monitoring Dashboard
- **Grafana** + **Prometheus** for metrics
- Track: Block time, gas usage, pending txs, peer count
- Alert on chain halts or slow blocks

### 6. Bridge to Polygon
- Lock UNY tokens on Polygon
- Mint wrapped UNY on Sovereign L1
- Enable cross-chain liquidity

---

## 🚀 Production Readiness Checklist

### Security
- [ ] Rotate deployer private key (CRITICAL - current key is compromised)
- [ ] Set up 3+ validator nodes (decentralization)
- [ ] Enable HTTPS for RPC endpoints (SSL/TLS)
- [ ] Firewall configuration (whitelist IPs)
- [ ] DDoS protection (Cloudflare, rate limiting)

### Infrastructure
- [ ] Deploy to cloud VPS (AWS/DigitalOcean/etc.)
- [ ] Set up monitoring (uptime, block production)
- [ ] Configure automatic restarts (systemd service)
- [ ] Database backups (chain data snapshots)
- [ ] Load balancer for RPC (multiple nodes)

### User Experience
- [ ] Deploy block explorer (Blockscout/Otterscan)
- [ ] Create faucet for testnet UNYETH
- [ ] Submit to ChainList for 1-click MetaMask add
- [ ] Documentation site (RPC URLs, contract ABIs)
- [ ] Status page (uptime monitoring)

### Smart Contracts
- [ ] Audit all 16 contracts (security review)
- [ ] Verify contracts on explorer (once Blockscout running)
- [ ] Upgrade Safe thresholds to multisig (3-of-5 admin)
- [ ] Test emergency pause mechanisms
- [ ] Set up multisig for contract upgrades

---

## 📞 Support & Resources

### Official Links
- **Polygon Deployment**: https://polygonscan.com (ChainID 137)
- **Localhost Dev**: http://127.0.0.1:8545 (ChainID 1337)
- **Sovereign L1**: http://127.0.0.1:8555 (ChainID 7777)

### Besu Documentation
- Official Docs: https://besu.hyperledger.org
- Clique Consensus: https://besu.hyperledger.org/private-networks/how-to/configure/consensus/clique

### MetaMask
- Add Network Guide: https://support.metamask.io/networks-and-sidechains/managing-networks/how-to-add-a-custom-network-rpc/

---

**Last Updated**: October 24, 2025  
**Deployment Block**: 20  
**Chain Status**: ✅ LIVE
