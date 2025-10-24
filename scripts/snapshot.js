const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

/**
 * Post-deployment snapshot script
 * Captures critical on-chain state for audit trail
 * Run: npx hardhat run scripts/snapshot.js --network polygon
 */

async function main() {
  console.log("\n📸 CAPTURING ON-CHAIN STATE SNAPSHOT\n");

  const network = await ethers.provider.getNetwork();
  const chainId = network.chainId;
  const blockNumber = await ethers.provider.getBlockNumber();
  const block = await ethers.provider.getBlock(blockNumber);

  console.log("Network:", network.name);
  console.log("Chain ID:", chainId);
  console.log("Block Number:", blockNumber);
  console.log("Block Timestamp:", new Date(Number(block.timestamp) * 1000).toISOString());

  // Load latest deployment
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  const files = fs.readdirSync(deploymentsDir).filter(f => f.startsWith("polygon-"));
  if (files.length === 0) {
    console.error("❌ No deployment files found. Deploy first!");
    process.exit(1);
  }

  const latestFile = files.sort().reverse()[0];
  const deployment = JSON.parse(
    fs.readFileSync(path.join(deploymentsDir, latestFile), "utf8")
  );

  console.log("\nLoaded deployment:", latestFile);
  console.log("\n" + "─".repeat(70));

  const snapshot = {
    network: network.name,
    chainId: Number(chainId),
    blockNumber: blockNumber,
    blockTimestamp: Number(block.timestamp),
    timestampISO: new Date(Number(block.timestamp) * 1000).toISOString(),
    deployment: latestFile,
    contracts: {},
  };

  // === UNY Token ===
  console.log("\n📊 UNY TOKEN (ERC-20)");
  console.log("Address:", deployment.contracts.UNYToken.address);
  
  const unyToken = await ethers.getContractAt("UNYToken", deployment.contracts.UNYToken.address);
  
  try {
    const name = await unyToken.name();
    const symbol = await unyToken.symbol();
    const decimals = await unyToken.decimals();
    const totalSupply = await unyToken.totalSupply();
    const owner = await unyToken.owner();
    const paused = await unyToken.paused();

    snapshot.contracts.UNYToken = {
      address: deployment.contracts.UNYToken.address,
      name,
      symbol,
      decimals,
      totalSupply: ethers.formatUnits(totalSupply, decimals),
      totalSupplyRaw: totalSupply.toString(),
      owner,
      paused,
    };

    console.log("  Name:", name);
    console.log("  Symbol:", symbol);
    console.log("  Decimals:", decimals);
    console.log("  Total Supply:", ethers.formatUnits(totalSupply, decimals));
    console.log("  Owner:", owner);
    console.log("  Paused:", paused);
  } catch (error) {
    console.log("  ⚠️  Error reading UNY token:", error.message);
  }

  // === VaultProofNFT ===
  console.log("\n🖼️  VAULTPROOF NFT (ERC-721)");
  console.log("Address:", deployment.contracts.VaultProofNFT.address);
  
  const vaultProofNFT = await ethers.getContractAt("VaultProofNFT", deployment.contracts.VaultProofNFT.address);
  
  try {
    const nftName = await vaultProofNFT.name();
    const nftSymbol = await vaultProofNFT.symbol();
    const owner = await vaultProofNFT.owner();
    const totalSupply = await vaultProofNFT.totalSupply();

    snapshot.contracts.VaultProofNFT = {
      address: deployment.contracts.VaultProofNFT.address,
      name: nftName,
      symbol: nftSymbol,
      owner,
      totalSupply: totalSupply.toString(),
    };

    console.log("  Name:", nftName);
    console.log("  Symbol:", nftSymbol);
    console.log("  Owner:", owner);
    console.log("  Total Supply:", totalSupply.toString());
  } catch (error) {
    console.log("  ⚠️  Error reading NFT:", error.message);
  }

  // === ComplianceRegistry ===
  console.log("\n✅ COMPLIANCE REGISTRY");
  console.log("Address:", deployment.contracts.ComplianceRegistry.address);
  
  const complianceRegistry = await ethers.getContractAt(
    "ComplianceRegistry",
    deployment.contracts.ComplianceRegistry.address
  );
  
  try {
    const owner = await complianceRegistry.owner();
    const paused = await complianceRegistry.paused();

    snapshot.contracts.ComplianceRegistry = {
      address: deployment.contracts.ComplianceRegistry.address,
      owner,
      paused,
    };

    console.log("  Owner:", owner);
    console.log("  Paused:", paused);
  } catch (error) {
    console.log("  ⚠️  Error reading registry:", error.message);
  }

  // === LaunchVault ===
  console.log("\n🚀 LAUNCH VAULT");
  console.log("Address:", deployment.contracts.LaunchVault.address);
  
  const launchVault = await ethers.getContractAt("LaunchVault", deployment.contracts.LaunchVault.address);
  
  try {
    const mintPrice = await launchVault.mintPrice();
    const owner = await launchVault.owner();
    const paused = await launchVault.paused();
    const balance = await ethers.provider.getBalance(deployment.contracts.LaunchVault.address);

    snapshot.contracts.LaunchVault = {
      address: deployment.contracts.LaunchVault.address,
      mintPrice: ethers.formatEther(mintPrice),
      mintPriceRaw: mintPrice.toString(),
      owner,
      paused,
      balance: ethers.formatEther(balance),
      balanceRaw: balance.toString(),
    };

    console.log("  Mint Price:", ethers.formatEther(mintPrice), "MATIC");
    console.log("  Owner:", owner);
    console.log("  Paused:", paused);
    console.log("  Balance:", ethers.formatEther(balance), "MATIC");
  } catch (error) {
    console.log("  ⚠️  Error reading launch vault:", error.message);
  }

  console.log("\n" + "─".repeat(70));

  // Save snapshot
  const snapshotDir = path.join(__dirname, "..", "snapshots");
  if (!fs.existsSync(snapshotDir)) {
    fs.mkdirSync(snapshotDir, { recursive: true });
  }

  const dateStr = new Date().toISOString().split("T")[0].replace(/-/g, "");
  const filename = `snapshot-${network.name}-${dateStr}-block${blockNumber}.json`;
  const filepath = path.join(snapshotDir, filename);

  fs.writeFileSync(filepath, JSON.stringify(snapshot, null, 2));
  console.log("\n💾 Snapshot saved to:", filename);

  // Print summary
  console.log("\n📋 SNAPSHOT SUMMARY:\n");
  console.log("Block Number:", snapshot.blockNumber);
  console.log("Timestamp:", snapshot.timestampISO);
  console.log("UNY Total Supply:", snapshot.contracts.UNYToken?.totalSupply || "N/A");
  console.log("NFT Total Supply:", snapshot.contracts.VaultProofNFT?.totalSupply || "N/A");
  console.log("Mint Price:", snapshot.contracts.LaunchVault?.mintPrice || "N/A", "MATIC");
  console.log("LaunchVault Balance:", snapshot.contracts.LaunchVault?.balance || "N/A", "MATIC");

  console.log("\n✅ Snapshot complete!\n");

  return snapshot;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Snapshot failed:", error);
    process.exit(1);
  });
