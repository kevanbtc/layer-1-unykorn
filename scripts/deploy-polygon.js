const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? "polygon" : network.name;
  const chainId = network.chainId;
  
  console.log("\n╔════════════════════════════════════════════════════════════════╗");
  console.log("║  🚀 POLYGON MAINNET DEPLOYMENT - UNYKORN VAULTPROOF SYSTEM    ║");
  console.log("╚════════════════════════════════════════════════════════════════╝\n");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying from account:", deployer.address);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "MATIC");
  
  if (balance < ethers.parseEther("0.1")) {
    console.log("⚠️  WARNING: Low balance! You need at least 0.1 MATIC for deployment.");
    console.log("   Fund your deployer address on Polygon mainnet first.\n");
    process.exit(1);
  }

  console.log("\n⏳ Starting deployment...\n");

  // Deployment configuration
  const TREASURY_ADDRESS = process.env.TREASURY_ADDRESS || deployer.address;
  const INITIAL_SUPPLY = process.env.INITIAL_SUPPLY || ethers.parseUnits("100000000", 18); // 100M UNY
  const MINT_PRICE = process.env.MINT_PRICE || ethers.parseEther("0.01"); // 0.01 MATIC

  console.log("📋 Deployment Parameters:");
  console.log("   Treasury Address:", TREASURY_ADDRESS);
  console.log("   Initial Supply:", ethers.formatUnits(INITIAL_SUPPLY, 18), "UNY");
  console.log("   NFT Mint Price:", ethers.formatEther(MINT_PRICE), "MATIC\n");

  // 1. Deploy UNY Token (ERC-20 with Permit)
  console.log("1️⃣  Deploying UNY Token (ERC-20 + Permit)...");
  const UNYToken = await ethers.getContractFactory("UNYToken");
  const unyToken = await UNYToken.deploy(TREASURY_ADDRESS, INITIAL_SUPPLY);
  await unyToken.waitForDeployment();
  const unyAddress = await unyToken.getAddress();
  console.log("   ✅ UNY Token deployed at:", unyAddress);

  // 2. Deploy VaultProofNFT (ERC-721)
  console.log("\n2️⃣  Deploying VaultProofNFT (ERC-721)...");
  const VaultProofNFT = await ethers.getContractFactory("VaultProofNFT");
  const vaultProofNFT = await VaultProofNFT.deploy();
  await vaultProofNFT.waitForDeployment();
  const nftAddress = await vaultProofNFT.getAddress();
  console.log("   ✅ VaultProofNFT deployed at:", nftAddress);

  // 3. Deploy ComplianceRegistry
  console.log("\n3️⃣  Deploying ComplianceRegistry...");
  const ComplianceRegistry = await ethers.getContractFactory("ComplianceRegistry");
  const complianceRegistry = await ComplianceRegistry.deploy();
  await complianceRegistry.waitForDeployment();
  const registryAddress = await complianceRegistry.getAddress();
  console.log("   ✅ ComplianceRegistry deployed at:", registryAddress);

  // 4. Deploy LaunchVault
  console.log("\n4️⃣  Deploying LaunchVault...");
  const LaunchVault = await ethers.getContractFactory("LaunchVault");
  const launchVault = await LaunchVault.deploy(
    registryAddress,
    nftAddress,
    MINT_PRICE
  );
  await launchVault.waitForDeployment();
  const launchAddress = await launchVault.getAddress();
  console.log("   ✅ LaunchVault deployed at:", launchAddress);

  // 5. Transfer NFT ownership to LaunchVault (so it can mint)
  console.log("\n5️⃣  Transferring VaultProofNFT ownership to LaunchVault...");
  const transferTx = await vaultProofNFT.transferOwnership(launchAddress);
  await transferTx.wait();
  console.log("   ✅ Ownership transferred");

  console.log("\n" + "═".repeat(64));
  console.log("🎉 DEPLOYMENT COMPLETE!");
  console.log("═".repeat(64) + "\n");

  // Create deployment record
  const deploymentRecord = {
    network: networkName,
    chainId: Number(chainId),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    blockNumber: await ethers.provider.getBlockNumber(),
    contracts: {
      UNYToken: {
        address: unyAddress,
        constructorArgs: [TREASURY_ADDRESS, INITIAL_SUPPLY.toString()],
      },
      VaultProofNFT: {
        address: nftAddress,
        constructorArgs: [],
      },
      ComplianceRegistry: {
        address: registryAddress,
        constructorArgs: [],
      },
      LaunchVault: {
        address: launchAddress,
        constructorArgs: [registryAddress, nftAddress, MINT_PRICE.toString()],
      },
    },
    configuration: {
      treasuryAddress: TREASURY_ADDRESS,
      initialSupply: ethers.formatUnits(INITIAL_SUPPLY, 18),
      mintPrice: ethers.formatEther(MINT_PRICE),
    },
  };

  // Get git commit hash if available
  try {
    const { execSync } = require("child_process");
    const commit = execSync("git rev-parse --short HEAD").toString().trim();
    deploymentRecord.commit = commit;
  } catch (e) {
    deploymentRecord.commit = "unknown";
  }

  // Save deployment record
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  const dateStr = new Date().toISOString().split("T")[0].replace(/-/g, "");
  const filename = `polygon-${dateStr}.json`;
  const filepath = path.join(deploymentsDir, filename);
  
  fs.writeFileSync(filepath, JSON.stringify(deploymentRecord, null, 2));
  console.log("💾 Deployment record saved to:", filename);

  // Print canonical addresses
  console.log("\n📋 CANONICAL ADDRESSES (save these!):\n");
  console.log("Network: Polygon (137)");
  console.log("UNY (ERC-20):          ", unyAddress);
  console.log("VaultProofNFT (ERC-721):", nftAddress);
  console.log("ComplianceRegistry:    ", registryAddress);
  console.log("LaunchVault:           ", launchAddress);
  console.log("Deployer:              ", deployer.address);
  console.log("Treasury:              ", TREASURY_ADDRESS);

  // Print verification commands
  console.log("\n🔍 VERIFICATION COMMANDS:\n");
  console.log("Run these to verify contracts on Polygonscan:\n");
  console.log(`npx hardhat verify --network polygon ${unyAddress} "${TREASURY_ADDRESS}" "${INITIAL_SUPPLY}"`);
  console.log(`npx hardhat verify --network polygon ${nftAddress}`);
  console.log(`npx hardhat verify --network polygon ${registryAddress}`);
  console.log(`npx hardhat verify --network polygon ${launchAddress} "${registryAddress}" "${nftAddress}" "${MINT_PRICE}"`);

  // Print next steps
  console.log("\n📝 NEXT STEPS:\n");
  console.log("1. Verify contracts on Polygonscan (commands above)");
  console.log("2. Pin NFT metadata to IPFS (Pinata/web3.storage)");
  console.log("3. Test mint via Hardhat console or frontend");
  console.log("4. Seed liquidity on QuickSwap (UNY/USDC pool)");
  console.log("5. Update README.md with canonical addresses");
  console.log("6. Run snapshot script: npx hardhat run scripts/snapshot.js --network polygon");
  console.log("7. Tag release: git tag -a v1.0.0 -m 'Mainnet launch'");
  console.log("\n✅ Deployment successful!\n");

  return deploymentRecord;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Deployment failed:", error);
    process.exit(1);
  });
