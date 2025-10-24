// Quick deployment script for L1 (chainId 7777 simulation)
// This deploys to Hardhat's local network and treats it like your L1

const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("\n🦄 DEPLOYING TO UNYKORN L1 (LOCAL)");
  console.log("═".repeat(60));

  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  
  console.log(`\n📡 Network: ${network.name}`);
  console.log(`📡 Chain ID: ${network.chainId}`);
  console.log(`👤 Deployer: ${deployer.address}`);
  console.log(`💰 Balance: ${hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address))} ETH`);

  const deployed = {};
  const startTime = Date.now();

  // Get Safe addresses from .env
  const ADMIN_SAFE = process.env.ADMIN_SAFE || deployer.address;
  const TREASURY_SAFE = process.env.TREASURY_SAFE || deployer.address;
  const COMPLIANCE_SAFE = process.env.COMPLIANCE_SAFE || deployer.address;
  const OPS_SAFE = process.env.OPS_SAFE || deployer.address;
  const GUARDIAN_EOA = process.env.GUARDIAN_EOA || deployer.address;

  console.log("\n🔐 Safe Addresses:");
  console.log(`   ADMIN: ${ADMIN_SAFE}`);
  console.log(`   TREASURY: ${TREASURY_SAFE}`);
  console.log(`   COMPLIANCE: ${COMPLIANCE_SAFE}`);
  console.log(`   OPS: ${OPS_SAFE}`);
  console.log(`   GUARDIAN: ${GUARDIAN_EOA}`);

  try {
    // 1. UNY Token
    console.log("\n1️⃣  Deploying UNYToken...");
    const UNYToken = await hre.ethers.getContractFactory("UNYToken");
    const unyToken = await UNYToken.deploy(TREASURY_SAFE, "100000000000000000000000000"); // 100M tokens
    await unyToken.waitForDeployment();
    deployed.unyToken = await unyToken.getAddress();
    console.log(`   ✅ UNYToken: ${deployed.unyToken}`);

    // 2. Compliance Registry
    console.log("\n2️⃣  Deploying ComplianceRegistry...");
    const ComplianceRegistry = await hre.ethers.getContractFactory("ComplianceRegistry");
    const complianceRegistry = await ComplianceRegistry.deploy();
    await complianceRegistry.waitForDeployment();
    deployed.complianceRegistry = await complianceRegistry.getAddress();
    console.log(`   ✅ ComplianceRegistry: ${deployed.complianceRegistry}`);

    // 3. VaultProof NFT
    console.log("\n3️⃣  Deploying VaultProofNFT...");
    const VaultProofNFT = await hre.ethers.getContractFactory("VaultProofNFT");
    const vaultProofNFT = await VaultProofNFT.deploy();
    await vaultProofNFT.waitForDeployment();
    deployed.vaultProofNFT = await vaultProofNFT.getAddress();
    console.log(`   ✅ VaultProofNFT: ${deployed.vaultProofNFT}`);

    // 4. LaunchVault
    console.log("\n4️⃣  Deploying LaunchVault...");
    const LaunchVault = await hre.ethers.getContractFactory("LaunchVault");
    const launchVault = await LaunchVault.deploy(
      deployed.complianceRegistry,
      deployed.vaultProofNFT,
      "10000000000000000" // 0.01 ETH mint price
    );
    await launchVault.waitForDeployment();
    deployed.launchVault = await launchVault.getAddress();
    console.log(`   ✅ LaunchVault: ${deployed.launchVault}`);

    // 5. Transfer VaultProofNFT ownership to LaunchVault
    console.log("\n5️⃣  Transferring VaultProofNFT ownership...");
    const tx = await vaultProofNFT.transferOwnership(deployed.launchVault);
    await tx.wait();
    console.log(`   ✅ Ownership transferred`);

    // 6. FeeRouter
    console.log("\n6️⃣  Deploying FeeRouter...");
    const FeeRouter = await hre.ethers.getContractFactory("FeeRouter");
    const feeRouter = await FeeRouter.deploy(TREASURY_SAFE);
    await feeRouter.waitForDeployment();
    deployed.feeRouter = await feeRouter.getAddress();
    console.log(`   ✅ FeeRouter: ${deployed.feeRouter}`);

    // 7. Price Oracle
    console.log("\n7️⃣  Deploying PriceOracle...");
    const PriceOracle = await hre.ethers.getContractFactory("PriceOracle");
    const priceOracle = await PriceOracle.deploy();
    await priceOracle.waitForDeployment();
    deployed.priceOracle = await priceOracle.getAddress();
    console.log(`   ✅ PriceOracle: ${deployed.priceOracle}`);

    // 8. REC Registry
    console.log("\n8️⃣  Deploying RECRegistry (ERC1155)...");
    const RECRegistry = await hre.ethers.getContractFactory("ERC1155REC");
    const recRegistry = await RECRegistry.deploy(
      "https://api.unykorn.org/recs/{id}.json",
      deployed.complianceRegistry,
      deployed.feeRouter
    );
    await recRegistry.waitForDeployment();
    deployed.recRegistry = await recRegistry.getAddress();
    console.log(`   ✅ RECRegistry: ${deployed.recRegistry}`);

    // 9. REC Marketplace
    console.log("\n9️⃣  Deploying RECMarketplace...");
    const RECMarketplace = await hre.ethers.getContractFactory("RECMarketplace");
    const recMarketplace = await RECMarketplace.deploy(
      deployed.recRegistry,
      deployed.feeRouter,
      deployed.complianceRegistry
    );
    await recMarketplace.waitForDeployment();
    deployed.recMarketplace = await recMarketplace.getAddress();
    console.log(`   ✅ RECMarketplace: ${deployed.recMarketplace}`);

    // 10. Retirement Attestation
    console.log("\n🔟 Deploying RetirementAttestation...");
    const RetirementAttestation = await hre.ethers.getContractFactory("RetirementAttestation");
    const retirementAttestation = await RetirementAttestation.deploy(
      deployed.recRegistry,
      deployed.complianceRegistry
    );
    await retirementAttestation.waitForDeployment();
    deployed.retirementAttestation = await retirementAttestation.getAddress();
    console.log(`   ✅ RetirementAttestation: ${deployed.retirementAttestation}`);

    const endTime = Date.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);

    console.log("\n" + "═".repeat(60));
    console.log("✅ DEPLOYMENT COMPLETE!");
    console.log("═".repeat(60));
    console.log(`⏱️  Duration: ${duration}s`);
    console.log(`📦 Contracts: ${Object.keys(deployed).length}`);

    // Save deployment
    const deploymentRecord = {
      network: "localhost",
      chainId: Number(network.chainId),
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
      block: await hre.ethers.provider.getBlockNumber(),
      safes: {
        ADMIN_SAFE,
        TREASURY_SAFE,
        COMPLIANCE_SAFE,
        OPS_SAFE,
        GUARDIAN_EOA
      },
      contracts: deployed
    };

    const deploymentsDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(deploymentsDir)) {
      fs.mkdirSync(deploymentsDir, { recursive: true });
    }

    const filename = path.join(deploymentsDir, "localhost.json");
    fs.writeFileSync(filename, JSON.stringify(deploymentRecord, null, 2));
    console.log(`\n💾 Saved: ${filename}`);

    console.log("\n📋 CONTRACT ADDRESSES:");
    console.log("─".repeat(60));
    console.log(`UNYToken:              ${deployed.unyToken}`);
    console.log(`ComplianceRegistry:    ${deployed.complianceRegistry}`);
    console.log(`VaultProofNFT:         ${deployed.vaultProofNFT}`);
    console.log(`LaunchVault:           ${deployed.launchVault}`);
    console.log(`FeeRouter:             ${deployed.feeRouter}`);
    console.log(`PriceOracle:           ${deployed.priceOracle}`);
    console.log(`RECRegistry:           ${deployed.recRegistry}`);
    console.log(`RECMarketplace:        ${deployed.recMarketplace}`);
    console.log(`RetirementAttestation: ${deployed.retirementAttestation}`);

    console.log("\n🎯 NEXT STEPS:");
    console.log("─".repeat(60));
    console.log("1. Update Safe App with these addresses");
    console.log("   - Edit: unykorn-safe-app/src/App.js");
    console.log("   - Update CONTRACTS.unykorn object");
    console.log("");
    console.log("2. Test minting:");
    console.log("   npx hardhat console --network localhost");
    console.log("   > const lv = await ethers.getContractAt('LaunchVault', '" + deployed.launchVault + "')");
    console.log("   > await lv.contribute({ value: ethers.parseEther('0.01') })");
    console.log("");
    console.log("3. Start Safe App:");
    console.log("   cd unykorn-safe-app");
    console.log("   npm start");
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
