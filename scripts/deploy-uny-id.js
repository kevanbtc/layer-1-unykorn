const hre = require("hardhat");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

/**
 * Deploy UNY-ID (Energy & RWA Passport) System
 * 
 * Contracts deployed:
 * 1. AttestationRegistry
 * 2. ComplianceRegistry
 * 3. IdentityNFT
 * 4. DeviceOracle
 * 5. ERC1155REC (Renewable Energy Certificates)
 * 6. ERC1400Adapter (Regulated Securities)
 * 7. RetirementLocker
 */

async function main() {
  console.log("\n🚀 UNY-ID SYSTEM DEPLOYMENT");
  console.log("═".repeat(60));

  const [deployer] = await hre.ethers.getSigners();
  const balance = await hre.ethers.provider.getBalance(deployer.address);

  console.log("\n📝 Deploying from account:", deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "MATIC");

  if (parseFloat(hre.ethers.formatEther(balance)) < 0.5) {
    throw new Error("❌ Insufficient balance. Need at least 0.5 MATIC for deployment.");
  }

  console.log("\n⏳ Starting deployment...\n");

  const deployedContracts = {};
  const startTime = Date.now();

  try {
    // ============ 1. AttestationRegistry ============
    console.log("1️⃣  Deploying AttestationRegistry...");
    const AttestationRegistry = await hre.ethers.getContractFactory("AttestationRegistry");
    const attestationRegistry = await AttestationRegistry.deploy();
    await attestationRegistry.waitForDeployment();
    const attestationRegistryAddress = await attestationRegistry.getAddress();
    console.log("   ✅ AttestationRegistry deployed at:", attestationRegistryAddress);
    deployedContracts.AttestationRegistry = {
      address: attestationRegistryAddress,
      constructorArgs: []
    };

    // ============ 2. ComplianceRegistry ============
    console.log("\n2️⃣  Deploying ComplianceRegistry...");
    const ComplianceRegistry = await hre.ethers.getContractFactory("ComplianceRegistry");
    const complianceRegistry = await ComplianceRegistry.deploy(attestationRegistryAddress);
    await complianceRegistry.waitForDeployment();
    const complianceRegistryAddress = await complianceRegistry.getAddress();
    console.log("   ✅ ComplianceRegistry deployed at:", complianceRegistryAddress);
    deployedContracts.ComplianceRegistry = {
      address: complianceRegistryAddress,
      constructorArgs: [attestationRegistryAddress]
    };

    // ============ 3. IdentityNFT ============
    console.log("\n3️⃣  Deploying IdentityNFT (UNY-ID Passport)...");
    const IdentityNFT = await hre.ethers.getContractFactory("IdentityNFT");
    const identityNFT = await IdentityNFT.deploy();
    await identityNFT.waitForDeployment();
    const identityNFTAddress = await identityNFT.getAddress();
    console.log("   ✅ IdentityNFT deployed at:", identityNFTAddress);
    deployedContracts.IdentityNFT = {
      address: identityNFTAddress,
      constructorArgs: []
    };

    // ============ 4. DeviceOracle ============
    console.log("\n4️⃣  Deploying DeviceOracle (MRV)...");
    const DeviceOracle = await hre.ethers.getContractFactory("DeviceOracle");
    const deviceOracle = await DeviceOracle.deploy(attestationRegistryAddress);
    await deviceOracle.waitForDeployment();
    const deviceOracleAddress = await deviceOracle.getAddress();
    console.log("   ✅ DeviceOracle deployed at:", deviceOracleAddress);
    deployedContracts.DeviceOracle = {
      address: deviceOracleAddress,
      constructorArgs: [attestationRegistryAddress]
    };

    // ============ 5. ERC1155REC ============
    console.log("\n5️⃣  Deploying ERC1155REC (Renewable Energy Certificates)...");
    const ERC1155REC = await hre.ethers.getContractFactory("ERC1155REC");
    const erc1155rec = await ERC1155REC.deploy(complianceRegistryAddress);
    await erc1155rec.waitForDeployment();
    const erc1155recAddress = await erc1155rec.getAddress();
    console.log("   ✅ ERC1155REC deployed at:", erc1155recAddress);
    deployedContracts.ERC1155REC = {
      address: erc1155recAddress,
      constructorArgs: [complianceRegistryAddress]
    };

    // ============ 6. ERC1400Adapter ============
    console.log("\n6️⃣  Deploying ERC1400Adapter (Regulated Securities)...");
    const ERC1400Adapter = await hre.ethers.getContractFactory("ERC1400Adapter");
    const erc1400adapter = await ERC1400Adapter.deploy(
      "Unykorn Energy Security Token",
      "UNYEST",
      complianceRegistryAddress,
      true // isControllable
    );
    await erc1400adapter.waitForDeployment();
    const erc1400adapterAddress = await erc1400adapter.getAddress();
    console.log("   ✅ ERC1400Adapter deployed at:", erc1400adapterAddress);
    deployedContracts.ERC1400Adapter = {
      address: erc1400adapterAddress,
      constructorArgs: [
        "Unykorn Energy Security Token",
        "UNYEST",
        complianceRegistryAddress,
        true
      ]
    };

    // ============ 7. RetirementLocker ============
    console.log("\n7️⃣  Deploying RetirementLocker (Carbon/REC Retirement)...");
    const RetirementLocker = await hre.ethers.getContractFactory("RetirementLocker");
    const retirementLocker = await RetirementLocker.deploy(attestationRegistryAddress);
    await retirementLocker.waitForDeployment();
    const retirementLockerAddress = await retirementLocker.getAddress();
    console.log("   ✅ RetirementLocker deployed at:", retirementLockerAddress);
    deployedContracts.RetirementLocker = {
      address: retirementLockerAddress,
      constructorArgs: [attestationRegistryAddress]
    };

    // ============ Save Deployment Record ============
    const deploymentTime = Date.now();
    const duration = ((deploymentTime - startTime) / 1000).toFixed(1);

    let gitCommit = "unknown";
    try {
      gitCommit = execSync("git rev-parse --short HEAD").toString().trim();
    } catch (e) {
      console.log("⚠️  Could not get git commit hash");
    }

    const blockNumber = await hre.ethers.provider.getBlockNumber();
    const network = hre.network.name;
    const chainId = (await hre.ethers.provider.getNetwork()).chainId;

    const deploymentRecord = {
      network: network,
      chainId: Number(chainId),
      deployer: deployer.address,
      timestamp: new Date(deploymentTime).toISOString(),
      blockNumber: blockNumber,
      deploymentDuration: `${duration}s`,
      contracts: deployedContracts,
      commit: gitCommit
    };

    const deploymentsDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(deploymentsDir)) {
      fs.mkdirSync(deploymentsDir, { recursive: true });
    }

    const date = new Date().toISOString().split("T")[0].replace(/-/g, "");
    const filename = `uny-id-${network}-${date}.json`;
    const filepath = path.join(deploymentsDir, filename);

    fs.writeFileSync(filepath, JSON.stringify(deploymentRecord, null, 2));

    console.log("\n" + "═".repeat(60));
    console.log("🎉 UNY-ID SYSTEM DEPLOYMENT COMPLETE!");
    console.log("═".repeat(60));

    console.log("\n💾 Deployment record saved to:", filename);

    console.log("\n📋 CANONICAL ADDRESSES (UNY-ID System):\n");
    console.log("Network:              ", network, `(Chain ID: ${chainId})`);
    console.log("AttestationRegistry:  ", attestationRegistryAddress);
    console.log("ComplianceRegistry:   ", complianceRegistryAddress);
    console.log("IdentityNFT:          ", identityNFTAddress);
    console.log("DeviceOracle:         ", deviceOracleAddress);
    console.log("ERC1155REC:           ", erc1155recAddress);
    console.log("ERC1400Adapter:       ", erc1400adapterAddress);
    console.log("RetirementLocker:     ", retirementLockerAddress);
    console.log("Deployer:             ", deployer.address);

    console.log("\n🔍 VERIFICATION COMMANDS:\n");
    console.log(`npx hardhat verify --network ${network} ${attestationRegistryAddress}`);
    console.log(`npx hardhat verify --network ${network} ${complianceRegistryAddress} "${attestationRegistryAddress}"`);
    console.log(`npx hardhat verify --network ${network} ${identityNFTAddress}`);
    console.log(`npx hardhat verify --network ${network} ${deviceOracleAddress} "${attestationRegistryAddress}"`);
    console.log(`npx hardhat verify --network ${network} ${erc1155recAddress} "${complianceRegistryAddress}"`);
    console.log(`npx hardhat verify --network ${network} ${erc1400adapterAddress} "Unykorn Energy Security Token" "UNYEST" "${complianceRegistryAddress}" true`);
    console.log(`npx hardhat verify --network ${network} ${retirementLockerAddress} "${attestationRegistryAddress}"`);

    console.log("\n📝 NEXT STEPS:\n");
    console.log("1. Verify contracts on Polygonscan:");
    console.log(`   npm run verify:unyid:${network}`);
    console.log("\n2. Configure compliance rules:");
    console.log("   - Set required VCs for token classes");
    console.log("   - Define jurisdiction restrictions");
    console.log("   - Authorize credential issuers");
    console.log("\n3. Register energy facilities & devices:");
    console.log("   - Mint IdentityNFTs for facilities");
    console.log("   - Register devices in DeviceOracle");
    console.log("   - Issue facility & device VCs");
    console.log("\n4. Create REC/EAC certificate types:");
    console.log("   - Define vintage/region/technology certificates");
    console.log("   - Set compliance class requirements");
    console.log("   - Assign serial prefixes");
    console.log("\n5. Configure registry bridges:");
    console.log("   - Add Verra/Gold Standard/I-REC bridges");
    console.log("   - Set oracle addresses for callbacks");
    console.log("\n6. Integration testing:");
    console.log("   - Test complete MRV → issuance → transfer → retirement flow");
    console.log("   - Verify compliance gates work correctly");
    console.log("   - Test registry bridge anti-double-count");

    console.log("\n✅ Deployment successful!");
    console.log(`⏱️  Total deployment time: ${duration}s\n`);

  } catch (error) {
    console.error("\n❌ DEPLOYMENT FAILED:", error.message);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
