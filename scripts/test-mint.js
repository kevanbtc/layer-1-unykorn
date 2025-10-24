// Quick test: Mint a VaultProof NFT on your L1
const hre = require("hardhat");

async function main() {
  console.log("\n🎫 MINTING VAULTPROOF NFT TEST\n");
  
  const [minter] = await hre.ethers.getSigners();
  console.log(`Minter: ${minter.address}`);
  console.log(`Balance: ${hre.ethers.formatEther(await hre.ethers.provider.getBalance(minter.address))} ETH\n`);

  // Load deployment for current network
  const { loadDeployment } = require("./lib/deployments");
  const deployment = loadDeployment(hre.network.name);
  
  const launchVaultAddress = deployment.contracts.launchVault;
  const nftAddress = deployment.contracts.vaultProofNFT;
  
  console.log(`LaunchVault: ${launchVaultAddress}`);
  console.log(`VaultProofNFT: ${nftAddress}\n`);

  // Get contracts
  const launchVault = await hre.ethers.getContractAt("LaunchVault", launchVaultAddress);
  const nft = await hre.ethers.getContractAt("VaultProofNFT", nftAddress);

  // Check mint price
  const mintPrice = await launchVault.mintPrice();
  console.log(`Mint Price: ${hre.ethers.formatEther(mintPrice)} ETH\n`);

  // Check NFT ownership
  const nftOwner = await nft.owner();
  console.log(`NFT Owner: ${nftOwner}`);
  console.log(`Expected: ${launchVaultAddress}`);
  
  if (nftOwner.toLowerCase() !== launchVaultAddress.toLowerCase()) {
    console.log("\n❌ ERROR: VaultProofNFT not owned by LaunchVault!");
    console.log("Run: npx hardhat run scripts/transfer-nft-ownership.js --network localhost\n");
    process.exit(1);
  }
  console.log("✅ Ownership correct\n");

  // Check if user already owns a token (idempotent test)
  const balance = await nft.balanceOf(minter.address);
  
  if (balance > 0n) {
    console.log(`✅ You already own ${balance} VaultProof NFT(s)!`);
    const tokenId = await nft.tokenOfOwnerByIndex(minter.address, 0);
    console.log(`   Token ID: ${tokenId}`);
    console.log(`   Mint Price: ${hre.ethers.formatEther(mintPrice)} ETH`);
    console.log(`\n🎉 SMOKE TEST PASSED! (NFT already minted)\n`);
    process.exit(0);
  }

  // Mint NFT
  console.log("🚀 Minting VaultProof NFT...");
  const tx = await launchVault.mint({ value: mintPrice });
  console.log(`   TX: ${tx.hash}`);
  
  const receipt = await tx.wait();
  console.log(`   ✅ Confirmed in block ${receipt.blockNumber}`);

  // Check balance after mint
  const balanceAfter = await nft.balanceOf(minter.address);
  console.log(`\n🎉 SUCCESS! You now own ${balanceAfter} VaultProof NFT(s)!`);

  // Get token ID
  if (balanceAfter > 0n) {
    const tokenId = await nft.tokenOfOwnerByIndex(minter.address, 0);
    console.log(`   Token ID: ${tokenId}`);
    console.log(`   View at: http://localhost:3000 (in Safe App)\n`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
