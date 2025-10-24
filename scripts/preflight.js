const { ethers } = require("hardhat");
require("dotenv").config();

/**
 * Pre-Flight Checklist - Run before deployment
 * Validates environment, balance, and configuration
 * Usage: node scripts/preflight.js
 */

async function main() {
  console.log("\n╔════════════════════════════════════════════════════════════════╗");
  console.log("║  ✈️  PRE-FLIGHT CHECKLIST - POLYGON MAINNET DEPLOYMENT       ║");
  console.log("╚════════════════════════════════════════════════════════════════╝\n");

  let allGood = true;
  const errors = [];
  const warnings = [];

  // Check 1: Environment variables
  console.log("1️⃣  Checking environment variables...");
  
  if (!process.env.POLYGON_RPC || process.env.POLYGON_RPC.includes("YOUR")) {
    errors.push("POLYGON_RPC not configured in .env");
    allGood = false;
  } else {
    console.log("   ✅ POLYGON_RPC configured");
  }

  if (!process.env.DEPLOYER_PK || process.env.DEPLOYER_PK.includes("YOUR")) {
    errors.push("DEPLOYER_PK not configured in .env");
    allGood = false;
  } else {
    console.log("   ✅ DEPLOYER_PK configured");
  }

  if (!process.env.POLYGONSCAN_API_KEY || process.env.POLYGONSCAN_API_KEY.includes("YOUR")) {
    warnings.push("POLYGONSCAN_API_KEY not configured (verification will fail)");
    console.log("   ⚠️  POLYGONSCAN_API_KEY missing (optional but recommended)");
  } else {
    console.log("   ✅ POLYGONSCAN_API_KEY configured");
  }

  // Check 2: RPC connectivity
  console.log("\n2️⃣  Testing Polygon RPC connection...");
  
  try {
    const provider = new ethers.JsonRpcProvider(process.env.POLYGON_RPC);
    const network = await provider.getNetwork();
    
    if (Number(network.chainId) !== 137) {
      errors.push(`Wrong network! Expected chainId 137, got ${network.chainId}`);
      allGood = false;
    } else {
      const blockNumber = await provider.getBlockNumber();
      console.log(`   ✅ Connected to Polygon (chainId: 137, block: ${blockNumber})`);
    }
  } catch (error) {
    errors.push(`RPC connection failed: ${error.message}`);
    allGood = false;
  }

  // Check 3: Deployer balance
  console.log("\n3️⃣  Checking deployer balance...");
  
  if (process.env.DEPLOYER_PK && !process.env.DEPLOYER_PK.includes("YOUR")) {
    try {
      const provider = new ethers.JsonRpcProvider(process.env.POLYGON_RPC);
      const wallet = new ethers.Wallet(process.env.DEPLOYER_PK, provider);
      const balance = await provider.getBalance(wallet.address);
      const balanceEth = ethers.formatEther(balance);
      
      console.log(`   📍 Deployer address: ${wallet.address}`);
      console.log(`   💰 Balance: ${balanceEth} MATIC`);
      
      if (balance < ethers.parseEther("0.5")) {
        errors.push(`Insufficient balance! Need at least 0.5 MATIC, have ${balanceEth}`);
        allGood = false;
      } else if (balance < ethers.parseEther("1.0")) {
        warnings.push(`Balance is ${balanceEth} MATIC. Consider adding more for retries.`);
        console.log("   ⚠️  Recommended: 1.0+ MATIC for safe deployment + retries");
      } else {
        console.log("   ✅ Sufficient balance for deployment");
      }
    } catch (error) {
      errors.push(`Failed to check balance: ${error.message}`);
      allGood = false;
    }
  }

  // Check 4: Contract files exist
  console.log("\n4️⃣  Checking contract files...");
  
  const fs = require("fs");
  const path = require("path");
  const contractsToCheck = [
    "contracts/tokens/UNYToken.sol",
    "contracts/tokens/VaultProofNFT.sol",
    "contracts/compliance/ComplianceRegistry.sol",
    "contracts/tokens/LaunchVault.sol"
  ];

  let contractsOk = true;
  for (const contract of contractsToCheck) {
    const filepath = path.join(__dirname, "..", contract);
    if (!fs.existsSync(filepath)) {
      errors.push(`Contract missing: ${contract}`);
      contractsOk = false;
      allGood = false;
    }
  }

  if (contractsOk) {
    console.log(`   ✅ All 4 core contracts found`);
  }

  // Check 5: Hardhat config
  console.log("\n5️⃣  Checking Hardhat configuration...");
  
  try {
    const config = require("../hardhat.config.js");
    
    if (config.solidity.version !== "0.8.24") {
      warnings.push(`Solidity version is ${config.solidity.version}, expected 0.8.24`);
    } else {
      console.log("   ✅ Solidity version: 0.8.24");
    }
    
    if (config.solidity.settings.optimizer.runs !== 2000) {
      warnings.push(`Optimizer runs is ${config.solidity.settings.optimizer.runs}, expected 2000`);
    } else {
      console.log("   ✅ Optimizer runs: 2000");
    }
    
    if (!config.etherscan || !config.etherscan.apiKey) {
      warnings.push("Etherscan config missing from hardhat.config.js");
    } else {
      console.log("   ✅ Etherscan verification configured");
    }
  } catch (error) {
    errors.push(`Failed to load hardhat.config.js: ${error.message}`);
    allGood = false;
  }

  // Check 6: Dependencies
  console.log("\n6️⃣  Checking dependencies...");
  
  try {
    const packageJson = require("../package.json");
    const requiredDeps = [
      "@openzeppelin/contracts",
      "ethers",
      "@nomicfoundation/hardhat-verify",
      "dotenv"
    ];
    
    let depsOk = true;
    for (const dep of requiredDeps) {
      if (!packageJson.dependencies[dep] && !packageJson.devDependencies[dep]) {
        errors.push(`Missing dependency: ${dep}`);
        depsOk = false;
        allGood = false;
      }
    }
    
    if (depsOk) {
      console.log("   ✅ All required dependencies installed");
    }
  } catch (error) {
    errors.push(`Failed to read package.json: ${error.message}`);
    allGood = false;
  }

  // Summary
  console.log("\n" + "═".repeat(64));
  
  if (allGood && warnings.length === 0) {
    console.log("🎉 ALL CHECKS PASSED - READY FOR DEPLOYMENT!");
    console.log("═".repeat(64) + "\n");
    
    console.log("📋 DEPLOYMENT SEQUENCE:\n");
    console.log("   1. npm run deploy:polygon      (~5 mins)");
    console.log("   2. npm run verify:polygon      (~10 mins)");
    console.log("   3. npm run snapshot:polygon    (~1 min)");
    console.log("\n✅ Run: npm run deploy:polygon\n");
    
    process.exit(0);
  } else {
    if (errors.length > 0) {
      console.log("❌ DEPLOYMENT BLOCKED - FIX THESE ERRORS:");
      console.log("═".repeat(64) + "\n");
      errors.forEach((err, i) => {
        console.log(`   ${i + 1}. ${err}`);
      });
      console.log();
    }
    
    if (warnings.length > 0) {
      console.log("⚠️  WARNINGS (non-blocking):");
      console.log("─".repeat(64) + "\n");
      warnings.forEach((warn, i) => {
        console.log(`   ${i + 1}. ${warn}`);
      });
      console.log();
    }
    
    console.log("Fix errors above, then run: node scripts/preflight.js\n");
    process.exit(errors.length > 0 ? 1 : 0);
  }
}

main().catch((error) => {
  console.error("\n❌ Pre-flight check failed:", error);
  process.exit(1);
});
