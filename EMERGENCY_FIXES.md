# 🆘 EMERGENCY TROUBLESHOOTING - QUICK FIXES

**Last Updated**: October 24, 2025  
**Keep this open during deployment!**

---

## 🔥 CRITICAL ERRORS (deployment blockers)

### "Error: insufficient funds for intrinsic transaction cost"
```
❌ Problem: Not enough MATIC for gas
✅ Fix: Send 0.5+ MATIC to deployer address
💡 Check balance: npm run preflight
```

### "Error: cannot estimate gas; transaction may fail"
```
❌ Problem: Contract constructor failing or wrong constructor args
✅ Fix: 
   1. Check contracts compile: npx hardhat compile
   2. Check .env has correct values (no YOUR_KEY_HERE placeholders)
   3. Retry with higher gas: Set gasPrice in hardhat.config.js
```

### "Error: nonce has already been used"
```
❌ Problem: Transaction already submitted (previous run)
✅ Fix: Check deployments/ folder - deployment may have succeeded
💡 If stuck: Clear nonce with a 0 MATIC transfer to self
```

### "Error: network does not support ENS"
```
❌ Problem: Wrong RPC URL or network config
✅ Fix: 
   1. Check POLYGON_RPC in .env (should be https://polygon-rpc.com)
   2. Verify chainId is 137 in hardhat.config.js
   3. Test RPC: curl -X POST $POLYGON_RPC -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

### "Error: invalid private key"
```
❌ Problem: DEPLOYER_PK malformed
✅ Fix: Must start with 0x and be 66 characters (64 hex + 0x prefix)
💡 Get from MetaMask: Settings → Security & Privacy → Reveal Secret Recovery Phrase
```

---

## ⚠️ VERIFICATION ERRORS (non-blocking, fix after deploy)

### "Fail - Unable to verify" or "Bytecode does not match"
```
❌ Problem: Compiler settings mismatch
✅ Fix: Check hardhat.config.js has EXACTLY:
   solidity: {
     version: "0.8.24",
     settings: { optimizer: { enabled: true, runs: 2000 } }
   }
💡 Then re-run: npm run verify:polygon
```

### "Already Verified"
```
✅ This is GOOD! Contract already verified from previous run.
💡 Check on Polygonscan - if green checkmark, you're done.
```

### "Max rate limit reached"
```
❌ Problem: Too many requests to Polygonscan API
✅ Fix: Wait 30 seconds, then retry: npm run verify:polygon
💡 Get API key at: https://polygonscan.com/myapikey
```

### "Invalid API Key"
```
❌ Problem: POLYGONSCAN_API_KEY wrong or missing
✅ Fix: 
   1. Get key at https://polygonscan.com/myapikey
   2. Add to .env: POLYGONSCAN_API_KEY=YOURKEY
   3. Retry: npm run verify:polygon
```

---

## 🐛 RUNTIME WARNINGS (usually safe to ignore)

### "Warning: SPDX license identifier not provided"
```
💡 Safe to ignore - our contracts have SPDX headers
```

### "npm audit - 13 low severity vulnerabilities"
```
💡 Safe to ignore for now (dev dependencies, no production risk)
⚠️ If concerned: npm audit fix (after deployment succeeds)
```

### "Gas estimation errored with the following message..."
```
💡 Hardhat trying to estimate gas - if deployment succeeds, ignore
⚠️ If deploy FAILS: Check contract constructor logic
```

---

## 🔄 RECOVERY PROCEDURES

### "Deployment stuck / hung / timed out"
```
1. Check transaction on Polygonscan (get deployer address from npm run preflight)
2. If transaction pending: Wait 5 mins, may confirm
3. If no transaction: Safe to re-run npm run deploy:polygon
4. If transaction failed: Check error on Polygonscan, fix issue, retry
```

### "Need to re-deploy (wrong config / test run)"
```
1. Deployments are immutable - you'll get new addresses
2. Safe to re-run: npm run deploy:polygon
3. Old contracts stay live (can't delete from blockchain)
4. Use latest addresses from deployments/*.json (sorted by date)
```

### "Lost deployment addresses!"
```
1. Check deployments/ folder - all saved as JSON
2. Latest file: ls deployments/ | sort | tail -1
3. Or check Polygonscan for deployer address history
4. Nuclear option: Re-deploy (new addresses)
```

---

## 📞 QUICK DIAGNOSTICS

### Check deployer balance
```powershell
npm run preflight
```

### Check if contracts compiled
```powershell
npx hardhat compile
```

### Check latest deployment
```powershell
cat deployments/polygon-*.json | Select-Object -Last 1
```

### Test RPC connection
```powershell
curl -X POST https://polygon-rpc.com -H "Content-Type: application/json" --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}'
# Should return: {"jsonrpc":"2.0","id":1,"result":"0x89"} (0x89 = 137 decimal)
```

### View contract on Polygonscan
```
https://polygonscan.com/address/YOUR_CONTRACT_ADDRESS
```

---

## 🎯 POST-DEPLOYMENT VALIDATION

### ✅ Deployment succeeded if:
- [x] All 4 contracts have addresses (not 0x000...)
- [x] `deployments/polygon-YYYYMMDD.json` file exists
- [x] Transaction confirmed on Polygonscan
- [x] npm run verify:polygon shows green checkmarks OR "Already Verified"

### ❌ Deployment failed if:
- [ ] Script errors before "DEPLOYMENT COMPLETE"
- [ ] Transaction reverted on Polygonscan
- [ ] Balance unchanged (transaction never sent)

---

## 🚨 WHEN TO PANIC (and what to do)

### "Funds drained / wallet compromised"
```
1. Stop all deployments immediately
2. Generate new wallet (MetaMask → Create Account)
3. Update .env with new DEPLOYER_PK
4. Never reuse compromised key
```

### "Wrong network (deployed to testnet/wrong chain)"
```
💡 No funds lost - just wrong chain
✅ Check hardhat.config.js network settings
✅ Verify POLYGON_RPC points to mainnet
✅ Re-deploy to correct network (costs gas again)
```

### "Contract has critical bug after deploy"
```
💡 Blockchain = immutable, can't edit deployed code
✅ Options:
   1. Deploy fixed version (new addresses)
   2. Use proxy pattern (if designed for it - ours aren't)
   3. Add pause/migration function (if coded)
⚠️ Prevention: Test on Mumbai testnet first!
```

---

## 📚 DOCUMENTATION QUICK LINKS

- **Full Deployment Guide**: `DEPLOYMENT_GUIDE.md`
- **UNY-ID System**: `UNY_ID_QUICKSTART.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`

---

## 💬 COMMON QUESTIONS

**Q: Can I cancel/undo a deployment?**  
A: No - blockchain is immutable. Deployed contracts stay forever.

**Q: Can I re-use same addresses on re-deploy?**  
A: No - each deployment gets new addresses.

**Q: How long until transactions confirm?**  
A: Usually 30-60 seconds on Polygon. Check Polygonscan.

**Q: What if verify fails but deploy succeeded?**  
A: Contracts work fine unverified. Re-run verify later.

**Q: Can I verify manually?**  
A: Yes - use commands printed by deploy script.

**Q: Mumbai testnet first?**  
A: Recommended! Change `.env` to MUMBAI_RPC, deploy, test, then mainnet.

---

**🆘 Still stuck?** Check `docs/TROUBLESHOOTING.md` for detailed walkthroughs.

**✅ Ready?** Run: `npm run preflight`
