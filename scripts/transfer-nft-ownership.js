/**
 * Transfer VaultProofNFT Ownership to LaunchVault
 * No file dependency - uses env vars or hardcoded addresses
 */

require("dotenv").config();
const hre = require("hardhat");
const { loadDeployment } = require("./lib/deployments");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  console.log("\n🔐 VaultProofNFT Ownership Transfer");
  console.log("════════════════════════════════════════════════════════");
  console.log("Deployer:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)), "MATIC");
  console.log("Network:", hre.network.name);
  console.log("ChainId:", (await hre.ethers.provider.getNetwork()).chainId);
  console.log("Block:", await hre.ethers.provider.getBlockNumber());
  
  // Load deployment for the current network
  const deployment = loadDeployment(hre.network.name);
  console.log("✅ Loaded deployment for:", hre.network.name);
  
  if (!deployment.contracts || !deployment.contracts.vaultProofNFT) {
    throw new Error("VaultProofNFT not deployed. Deploy it first.");
  }
  
  if (!deployment.contracts.launchVault) {
    throw new Error("LaunchVault not deployed. Deploy it first.");
  }
  
  console.log("\n📄 Contract Addresses:");
  console.log("   VaultProofNFT:", deployment.contracts.vaultProofNFT);
  console.log("   LaunchVault:", deployment.contracts.launchVault);
  
  // Get contract instance
  const VaultProofNFT = await hre.ethers.getContractFactory("VaultProofNFT");
  const vaultProofNFT = VaultProofNFT.attach(deployment.contracts.vaultProofNFT);
  
  // Check current owner
  const currentOwner = await vaultProofNFT.owner();
  console.log("\n🔍 Current Owner:", currentOwner);
  
  if (currentOwner.toLowerCase() === deployment.contracts.launchVault.toLowerCase()) {
    console.log("✅ Ownership already transferred!");
    return;
  }
  
  if (currentOwner.toLowerCase() !== deployer.address.toLowerCase()) {
    throw new Error(`You are not the owner. Current owner: ${currentOwner}`);
  }
  
  // Transfer ownership
  console.log("\n🔄 Transferring ownership to LaunchVault...");
  const tx = await vaultProofNFT.transferOwnership(deployment.contracts.launchVault);
  console.log("   Transaction:", tx.hash);
  
  const receipt = await tx.wait();
  console.log("   ✅ Ownership transferred!");
  console.log("   Gas Used:", receipt.gasUsed.toString());
  console.log("   Block:", receipt.blockNumber);
  
  // Verify new owner
  const newOwner = await vaultProofNFT.owner();
  console.log("\n✅ New Owner:", newOwner);
  
  if (newOwner.toLowerCase() !== deployment.contracts.launchVault.toLowerCase()) {
    throw new Error("Ownership transfer failed!");
  }
  
  console.log("\n🎉 SUCCESS! LaunchVault can now mint VaultProofNFTs.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ ERROR:", error.message);
    process.exit(1);
  });
