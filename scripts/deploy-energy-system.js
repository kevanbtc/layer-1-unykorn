const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

/**
 * FULL ENERGY SYSTEM DEPLOYMENT
 * Deploys all 16 contracts in correct dependency order
 * 
 * ⚠️ MAINNET GUARD: Requires CONFIRM_MAINNET=YES for Polygon deployments
 */

async function main() {
  const { network } = hre;
  const deploymentPath = path.join(__dirname, "..", "deployments", `${network.name}.json`);
  
  // 🛡️ MAINNET GUARD: Prevent accidental Polygon mainnet deployments
  if (network.config.chainId === 137 && process.env.CONFIRM_MAINNET !== "YES") {
    throw new Error(`
╔════════════════════════════════════════════════════════════╗
║  ⚠️  POLYGON MAINNET DEPLOYMENT BLOCKED                   ║
║                                                            ║
║  You're trying to deploy to Polygon mainnet (ChainId 137) ║
║  Set CONFIRM_MAINNET=YES to proceed.                      ║
║                                                            ║
║  Recommended: Deploy to Unykorn L1 first (FREE GAS!)      ║
║  > npm run deploy:energy:unykorn                          ║
╚════════════════════════════════════════════════════════════╝
    `.trim());
  }
  
  console.log("\n🚀 DEPLOYING UNYKORN GLOBAL ENERGY & CARBON SYSTEM\n");
  console.log("═".repeat(60));
  
  const [deployer] = await hre.ethers.getSigners();
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  const networkInfo = await hre.ethers.provider.getNetwork();
  const networkName = hre.network.name;
  const chainId = Number(networkInfo.chainId);
  // Determine EIP-1559 fee overrides to satisfy Besu's min gas/basefee requirements
  const feeData = await hre.ethers.provider.getFeeData();
  const overrides = {};
  if (feeData.maxFeePerGas) overrides.maxFeePerGas = feeData.maxFeePerGas;
  // Some Besu setups accept 0 priority; prefer whatever the node suggests
  overrides.maxPriorityFeePerGas = feeData.maxPriorityFeePerGas ?? 0n;
  
  console.log("Network:", networkName);
  console.log("ChainId:", chainId);
  console.log("Deployer:", deployer.address);
  console.log("FeeData:", {
    gasPrice: feeData.gasPrice?.toString?.() ?? null,
    maxFeePerGas: feeData.maxFeePerGas?.toString?.() ?? null,
    maxPriorityFeePerGas: feeData.maxPriorityFeePerGas?.toString?.() ?? null,
  });
  
  if (chainId === 7777) {
    console.log("Balance:", hre.ethers.formatEther(balance), "UNYETH 💎 (FREE GAS!)");
  } else {
    console.log("Balance:", hre.ethers.formatEther(balance), chainId === 137 ? "MATIC" : "ETH");
  }
  console.log("");
  
  // Load previous deployment (resume support)
  let deployed = {};
  try {
    if (fs.existsSync(deploymentPath)) {
      const prev = JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
      if (prev && prev.contracts && typeof prev.contracts === "object") {
        deployed = { ...prev.contracts };
        if (Object.keys(deployed).length > 0) {
          console.log("\n↩️  Resuming from previous deployment progress (" + Object.keys(deployed).length + " contracts)\n");
        }
      }
    }
  } catch (e) {
    console.warn("⚠️  Unable to read previous deployments file:", e.message);
  }

  const saveProgress = async () => {
    const block = await hre.ethers.provider.getBlockNumber();
    const info = {
      network: hre.network.name,
      chainId: hre.network.config.chainId,
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
      block,
      contracts: deployed,
    };
    fs.mkdirSync(path.dirname(deploymentPath), { recursive: true });
    fs.writeFileSync(deploymentPath, JSON.stringify(info, null, 2));
  };
  const startTime = Date.now();
  
  try {
    // ═══════════════════════════════════════════════════════════
    // PHASE 1: CORE TOKENS (4 contracts)
    // ═══════════════════════════════════════════════════════════
    console.log("📦 PHASE 1: Core Tokens");
    console.log("─".repeat(60));
    
    // 1. UNY Token
    console.log("1/16: Deploying UNYToken...");
    if (!deployed.unyToken) {
      const initialSupply = hre.ethers.parseEther("100000000"); // 100M initial (10% of max)
      const UNYToken = await hre.ethers.getContractFactory("UNYToken");
  const unyToken = await UNYToken.deploy(deployer.address, initialSupply, overrides);
      console.log("   ↪ tx:", unyToken.deploymentTransaction().hash);
      await unyToken.waitForDeployment();
      deployed.unyToken = await unyToken.getAddress();
      await saveProgress();
      console.log("✅ UNYToken:", deployed.unyToken);
    } else {
      console.log("⏭️  UNYToken already deployed:", deployed.unyToken);
    }
    
    // 2. ComplianceRegistry (basic version - needed for LaunchVault)
    console.log("\n2/16: Deploying ComplianceRegistry...");
    if (!deployed.complianceRegistry) {
      const ComplianceRegistry = await hre.ethers.getContractFactory("ComplianceRegistry");
  const complianceRegistry = await ComplianceRegistry.deploy(overrides);
      console.log("   ↪ tx:", complianceRegistry.deploymentTransaction().hash);
      await complianceRegistry.waitForDeployment();
      deployed.complianceRegistry = await complianceRegistry.getAddress();
      await saveProgress();
      console.log("✅ ComplianceRegistry:", deployed.complianceRegistry);
    } else {
      console.log("⏭️  ComplianceRegistry already deployed:", deployed.complianceRegistry);
    }
    
    // 3. VaultProofNFT
    console.log("\n3/16: Deploying VaultProofNFT...");
    if (!deployed.vaultProofNFT) {
      const VaultProofNFT = await hre.ethers.getContractFactory("VaultProofNFT");
  const vaultProofNFT = await VaultProofNFT.deploy(overrides);
      console.log("   ↪ tx:", vaultProofNFT.deploymentTransaction().hash);
      await vaultProofNFT.waitForDeployment();
      deployed.vaultProofNFT = await vaultProofNFT.getAddress();
      await saveProgress();
      console.log("✅ VaultProofNFT:", deployed.vaultProofNFT);
    } else {
      console.log("⏭️  VaultProofNFT already deployed:", deployed.vaultProofNFT);
    }
    
    // 4. LaunchVault
    console.log("\n4/16: Deploying LaunchVault...");
    const mintPrice = hre.ethers.parseEther("10"); // 10 MATIC
    if (!deployed.launchVault) {
      const LaunchVault = await hre.ethers.getContractFactory("LaunchVault");
      const launchVault = await LaunchVault.deploy(
        deployed.complianceRegistry,
        deployed.vaultProofNFT,
        mintPrice,
        overrides
      );
      console.log("   ↪ tx:", launchVault.deploymentTransaction().hash);
      await launchVault.waitForDeployment();
      deployed.launchVault = await launchVault.getAddress();
      await saveProgress();
      console.log("✅ LaunchVault:", deployed.launchVault);
    } else {
      console.log("⏭️  LaunchVault already deployed:", deployed.launchVault);
    }
    
    // Note: VaultProofNFT ownership transfer to LaunchVault must be done manually
    console.log("\n   ⚠️  MANUAL STEP REQUIRED:");
    console.log(`   Transfer VaultProofNFT ownership: vaultProofNFT.transferOwnership("${deployed.launchVault}")`);
    console.log("   Or run: npx hardhat run scripts/transfer-nft-ownership.js --network polygon");
    
    // ═══════════════════════════════════════════════════════════
    // PHASE 2: LICENSING (3 contracts)
    // ═══════════════════════════════════════════════════════════
    console.log("\n\n📜 PHASE 2: Licensing & Royalties");
    console.log("─".repeat(60));
    
    // 5. RoyaltySplitter
    console.log("5/16: Deploying RoyaltySplitter...");
    if (!deployed.royaltySplitter) {
      const RoyaltySplitter = await hre.ethers.getContractFactory("RoyaltySplitter");
  const royaltySplitter = await RoyaltySplitter.deploy(overrides);
      console.log("   ↪ tx:", royaltySplitter.deploymentTransaction().hash);
      await royaltySplitter.waitForDeployment();
      deployed.royaltySplitter = await royaltySplitter.getAddress();
      await saveProgress();
      console.log("✅ RoyaltySplitter:", deployed.royaltySplitter);
    } else {
      console.log("⏭️  RoyaltySplitter already deployed:", deployed.royaltySplitter);
    }
    
    // 6. FeeRouter
    console.log("\n6/16: Deploying FeeRouter...");
    if (!deployed.feeRouter) {
      const FeeRouter = await hre.ethers.getContractFactory("FeeRouter");
  const feeRouter = await FeeRouter.deploy(deployed.royaltySplitter, overrides);
      console.log("   ↪ tx:", feeRouter.deploymentTransaction().hash);
      await feeRouter.waitForDeployment();
      deployed.feeRouter = await feeRouter.getAddress();
      await saveProgress();
      console.log("✅ FeeRouter:", deployed.feeRouter);
    } else {
      console.log("⏭️  FeeRouter already deployed:", deployed.feeRouter);
    }
    
    // 7. LicenseNFT
    console.log("\n7/16: Deploying LicenseNFT...");
    if (!deployed.licenseNFT) {
      const LicenseNFT = await hre.ethers.getContractFactory("LicenseNFT");
  const licenseNFT = await LicenseNFT.deploy(overrides);
      console.log("   ↪ tx:", licenseNFT.deploymentTransaction().hash);
      await licenseNFT.waitForDeployment();
      deployed.licenseNFT = await licenseNFT.getAddress();
      await saveProgress();
      console.log("✅ LicenseNFT:", deployed.licenseNFT);
    } else {
      console.log("⏭️  LicenseNFT already deployed:", deployed.licenseNFT);
    }
    
    // ═══════════════════════════════════════════════════════════
    // PHASE 3: ORACLES (4 contracts - includes DeviceOracle from UNY-ID)
    // ═══════════════════════════════════════════════════════════
    console.log("\n\n🔮 PHASE 3: Oracle Layer");
    console.log("─".repeat(60));
    
    // 8. PriceOracle
    console.log("8/16: Deploying PriceOracle...");
    if (!deployed.priceOracle) {
      const PriceOracle = await hre.ethers.getContractFactory("PriceOracle");
  const priceOracle = await PriceOracle.deploy(overrides);
      console.log("   ↪ tx:", priceOracle.deploymentTransaction().hash);
      await priceOracle.waitForDeployment();
      deployed.priceOracle = await priceOracle.getAddress();
      await saveProgress();
      console.log("✅ PriceOracle:", deployed.priceOracle);
    } else {
      console.log("⏭️  PriceOracle already deployed:", deployed.priceOracle);
    }
    
    // 9. ComplianceOracle
    console.log("\n9/16: Deploying ComplianceOracle...");
    if (!deployed.complianceOracle) {
      const ComplianceOracle = await hre.ethers.getContractFactory("ComplianceOracle");
  const complianceOracle = await ComplianceOracle.deploy(overrides);
      console.log("   ↪ tx:", complianceOracle.deploymentTransaction().hash);
      await complianceOracle.waitForDeployment();
      deployed.complianceOracle = await complianceOracle.getAddress();
      await saveProgress();
      console.log("✅ ComplianceOracle:", deployed.complianceOracle);
    } else {
      console.log("⏭️  ComplianceOracle already deployed:", deployed.complianceOracle);
    }
    
    // 10. WeatherOracle
    console.log("\n10/16: Deploying WeatherOracle...");
    if (!deployed.weatherOracle) {
      const WeatherOracle = await hre.ethers.getContractFactory("WeatherOracle");
  const weatherOracle = await WeatherOracle.deploy(overrides);
      console.log("   ↪ tx:", weatherOracle.deploymentTransaction().hash);
      await weatherOracle.waitForDeployment();
      deployed.weatherOracle = await weatherOracle.getAddress();
      await saveProgress();
      console.log("✅ WeatherOracle:", deployed.weatherOracle);
    } else {
      console.log("⏭️  WeatherOracle already deployed:", deployed.weatherOracle);
    }
    
    // 11. DeviceOracle (skipped - UNY-ID dependency)
    console.log("\n11/16: Skipping DeviceOracle (UNY-ID system)");
    
    // ═══════════════════════════════════════════════════════════
    // PHASE 4: ADVANCED TOKENS (3 contracts)
    // ═══════════════════════════════════════════════════════════
    console.log("\n\n🪙 PHASE 4: Advanced Tokens");
    console.log("─".repeat(60));
    
    // 12. ERC1155Carbon
    console.log("12/16: Deploying ERC1155Carbon...");
    if (!deployed.carbonToken) {
      const ERC1155Carbon = await hre.ethers.getContractFactory("ERC1155Carbon");
  const carbonToken = await ERC1155Carbon.deploy(overrides);
      console.log("   ↪ tx:", carbonToken.deploymentTransaction().hash);
      await carbonToken.waitForDeployment();
      deployed.carbonToken = await carbonToken.getAddress();
      await saveProgress();
      console.log("✅ ERC1155Carbon:", deployed.carbonToken);
    } else {
      console.log("⏭️  ERC1155Carbon already deployed:", deployed.carbonToken);
    }
    
    // 13. ERC1400TaxEquity
    console.log("\n13/16: Deploying ERC1400TaxEquity...");
    if (!deployed.taxEquityToken) {
      const ERC1400TaxEquity = await hre.ethers.getContractFactory("ERC1400TaxEquity");
  const taxEquityToken = await ERC1400TaxEquity.deploy("UNY Tax Equity", "UNYTE", overrides);
      console.log("   ↪ tx:", taxEquityToken.deploymentTransaction().hash);
      await taxEquityToken.waitForDeployment();
      deployed.taxEquityToken = await taxEquityToken.getAddress();
      await saveProgress();
      console.log("✅ ERC1400TaxEquity:", deployed.taxEquityToken);
    } else {
      console.log("⏭️  ERC1400TaxEquity already deployed:", deployed.taxEquityToken);
    }
    
    // 14. ERC3643Adapter
    console.log("\n14/16: Deploying ERC3643Adapter...");
    // Note: Uses ComplianceRegistry as identity registry for now
    if (!deployed.trexAdapter) {
      const ERC3643Adapter = await hre.ethers.getContractFactory("ERC3643Adapter");
      const trexAdapter = await ERC3643Adapter.deploy(
        "UNY Securities",
        "UNYSEC",
        deployed.complianceRegistry, // identity registry
        deployed.complianceRegistry, // compliance module
        overrides
      );
      console.log("   ↪ tx:", trexAdapter.deploymentTransaction().hash);
      await trexAdapter.waitForDeployment();
      deployed.trexAdapter = await trexAdapter.getAddress();
      await saveProgress();
      console.log("✅ ERC3643Adapter:", deployed.trexAdapter);
    } else {
      console.log("⏭️  ERC3643Adapter already deployed:", deployed.trexAdapter);
    }
    
    // ═══════════════════════════════════════════════════════════
    // PHASE 5: RETIREMENT (2 contracts)
    // ═══════════════════════════════════════════════════════════
    console.log("\n\n♻️  PHASE 5: Retirement System");
    console.log("─".repeat(60));
    
    // 15. BufferPool
    console.log("15/16: Deploying BufferPool...");
    if (!deployed.bufferPool) {
  const BufferPool = await hre.ethers.getContractFactory("BufferPool");
  const bufferPool = await BufferPool.deploy(overrides);
      console.log("   ↪ tx:", bufferPool.deploymentTransaction().hash);
      await bufferPool.waitForDeployment();
      deployed.bufferPool = await bufferPool.getAddress();
      await saveProgress();
      console.log("✅ BufferPool:", deployed.bufferPool);
    } else {
      console.log("⏭️  BufferPool already deployed:", deployed.bufferPool);
    }
    
    // 16. RetirementAttestation
    console.log("\n16/16: Deploying RetirementAttestation...");
    if (!deployed.retirementAttestation) {
  const RetirementAttestation = await hre.ethers.getContractFactory("RetirementAttestation");
  const retirementAttestation = await RetirementAttestation.deploy(overrides);
      console.log("   ↪ tx:", retirementAttestation.deploymentTransaction().hash);
      await retirementAttestation.waitForDeployment();
      deployed.retirementAttestation = await retirementAttestation.getAddress();
      await saveProgress();
      console.log("✅ RetirementAttestation:", deployed.retirementAttestation);
    } else {
      console.log("⏭️  RetirementAttestation already deployed:", deployed.retirementAttestation);
    }
    
    // ═══════════════════════════════════════════════════════════
    // PHASE 6: MARKETS (1 contract - more can be added)
    // ═══════════════════════════════════════════════════════════
    console.log("\n\n🏪 PHASE 6: Marketplaces");
    console.log("─".repeat(60));
    
    // 17. RECMarketplace
    console.log("17/17: Deploying RECMarketplace...");
    if (!deployed.recMarketplace) {
  const RECMarketplace = await hre.ethers.getContractFactory("RECMarketplace");
  const recMarketplace = await RECMarketplace.deploy(deployed.feeRouter, overrides);
      console.log("   ↪ tx:", recMarketplace.deploymentTransaction().hash);
      await recMarketplace.waitForDeployment();
      deployed.recMarketplace = await recMarketplace.getAddress();
      await saveProgress();
      console.log("✅ RECMarketplace:", deployed.recMarketplace);
    } else {
      console.log("⏭️  RECMarketplace already deployed:", deployed.recMarketplace);
    }
    
    // ═══════════════════════════════════════════════════════════
    // SUMMARY
    // ═══════════════════════════════════════════════════════════
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    
    console.log("\n\n");
    console.log("═".repeat(60));
    console.log("✨ DEPLOYMENT COMPLETE");
    console.log("═".repeat(60));
    console.log(`Time: ${duration}s`);
    console.log(`Network: ${hre.network.name}`);
    console.log(`Deployer: ${deployer.address}`);
    console.log(`Contracts: ${Object.keys(deployed).length}`);
    
    console.log("\n📋 DEPLOYED CONTRACTS:");
    console.log("─".repeat(60));
    
    const categories = {
      "Core Tokens": ["unyToken", "complianceRegistry", "vaultProofNFT", "launchVault"],
      "Licensing": ["licenseNFT", "royaltySplitter", "feeRouter"],
      "Oracles": ["priceOracle", "complianceOracle", "weatherOracle"],
      "Advanced Tokens": ["carbonToken", "taxEquityToken", "trexAdapter"],
      "Retirement": ["bufferPool", "retirementAttestation"],
      "Markets": ["recMarketplace"]
    };
    
    for (const [category, contracts] of Object.entries(categories)) {
      console.log(`\n${category}:`);
      for (const contract of contracts) {
        console.log(`  ${contract}: ${deployed[contract]}`);
      }
    }
    
    // Final save
    await saveProgress();
    console.log(`\n💾 Saved to: ${deploymentPath}`);
    
    // Generate verification commands (only for networks with block explorers)
    if (chainId === 137) {
      console.log("\n📝 VERIFICATION COMMANDS (Polygonscan):");
      console.log("─".repeat(60));
      console.log("\n# Core Tokens");
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.unyToken}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.complianceRegistry}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.vaultProofNFT}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.launchVault} ${deployed.complianceRegistry} ${deployed.vaultProofNFT} ${mintPrice}`);
      
      console.log("\n# Licensing");
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.royaltySplitter}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.feeRouter} ${deployed.royaltySplitter}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.licenseNFT}`);
      
      console.log("\n# Oracles");
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.priceOracle}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.complianceOracle}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.weatherOracle}`);
      
      console.log("\n# Advanced Tokens");
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.carbonToken}`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.taxEquityToken} "UNY Tax Equity" "UNYTE"`);
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.trexAdapter} "UNY Securities" "UNYSEC" ${deployed.complianceRegistry} ${deployed.complianceRegistry}`);
      
      console.log("\n# Retirement");
      console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.bufferPool}`);
    console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.retirementAttestation}`);
    
    console.log("\n# Markets");
    console.log(`npx hardhat verify --network ${hre.network.name} ${deployed.recMarketplace} ${deployed.feeRouter}`);
    } else if (chainId === 7777) {
      console.log("\n✅ Unykorn L1 deployment complete! (Sourcify verification automatic)");
    }
    
    console.log("\n\n🎉 READY FOR PRODUCTION!");
    console.log("═".repeat(60));
    console.log("\n✅ Next steps:");
    if (chainId === 7777) {
      console.log("  1. Create 4 Gnosis Safes on Safe.global");
      console.log("  2. Run: npm run wire:safes:unykorn");
      console.log("  3. Test contribution flow (LaunchVault)");
      console.log("  4. Configure oracles (price feeds, compliance)");
      console.log("  5. Deploy bridge contracts (optional)");
    } else {
      console.log("  1. Run verification commands above");
      console.log("  2. Test basic flows (mint, transfer, retire)");
      console.log("  3. Load policy packs for compliance rules");
      console.log("  4. Issue licenses for pilot facilities");
      console.log("  5. Configure oracles (price feeds, compliance data)");
    }
    console.log("\n");
    
  } catch (error) {
    console.error("\n❌ DEPLOYMENT FAILED:");
    console.error(error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
