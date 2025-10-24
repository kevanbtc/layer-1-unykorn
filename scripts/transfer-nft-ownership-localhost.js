// Transfer VaultProofNFT ownership to LaunchVault (localhost)
const hre = require("hardhat");

async function main() {
  console.log("\n🔐 TRANSFERRING NFT OWNERSHIP\n");
  
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deployer: ${deployer.address}\n`);

  // Load deployment
  const deployment = require("../deployments/localhost.json");
  
  const nftAddress = deployment.contracts.vaultProofNFT;
  const launchVaultAddress = deployment.contracts.launchVault;
  
  console.log(`VaultProofNFT: ${nftAddress}`);
  console.log(`LaunchVault: ${launchVaultAddress}\n`);

  // Get NFT contract
  const nft = await hre.ethers.getContractAt("VaultProofNFT", nftAddress);

  // Check current owner
  const currentOwner = await nft.owner();
  console.log(`Current Owner: ${currentOwner}`);

  if (currentOwner.toLowerCase() === launchVaultAddress.toLowerCase()) {
    console.log("✅ Already owned by LaunchVault!\n");
    return;
  }

  // Transfer ownership
  console.log("\n🔄 Transferring ownership...");
  const tx = await nft.transferOwnership(launchVaultAddress);
  console.log(`   TX: ${tx.hash}`);
  
  const receipt = await tx.wait();
  console.log(`   ✅ Confirmed in block ${receipt.blockNumber}`);

  // Verify
  const newOwner = await nft.owner();
  console.log(`\n   New Owner: ${newOwner}`);
  
  if (newOwner.toLowerCase() === launchVaultAddress.toLowerCase()) {
    console.log("   ✅ SUCCESS! Ownership transferred!\n");
  } else {
    console.log("   ❌ ERROR: Ownership not transferred correctly\n");
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
