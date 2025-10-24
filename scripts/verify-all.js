const { ethers } = require("hardhat");

/**
 * Verify contracts on Polygonscan
 * Run after deployment: npx hardhat run scripts/verify-all.js --network polygon
 */

async function main() {
  const fs = require("fs");
  const path = require("path");

  console.log("\n🔍 VERIFYING CONTRACTS ON POLYGONSCAN\n");

  // Load latest deployment
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  const files = fs.readdirSync(deploymentsDir).filter(f => f.startsWith("polygon-"));
  
  if (files.length === 0) {
    console.error("❌ No deployment files found!");
    process.exit(1);
  }

  const latestFile = files.sort().reverse()[0];
  const deployment = JSON.parse(
    fs.readFileSync(path.join(deploymentsDir, latestFile), "utf8")
  );

  console.log("Loaded deployment:", latestFile);
  console.log("\nVerifying contracts...\n");

  const { run } = require("hardhat");

  // 1. Verify UNY Token
  console.log("1️⃣  Verifying UNY Token...");
  try {
    await run("verify:verify", {
      address: deployment.contracts.UNYToken.address,
      constructorArguments: deployment.contracts.UNYToken.constructorArgs,
    });
    console.log("   ✅ UNY Token verified");
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("   ℹ️  Already verified");
    } else {
      console.log("   ❌ Error:", error.message);
    }
  }

  // 2. Verify VaultProofNFT
  console.log("\n2️⃣  Verifying VaultProofNFT...");
  try {
    await run("verify:verify", {
      address: deployment.contracts.VaultProofNFT.address,
      constructorArguments: deployment.contracts.VaultProofNFT.constructorArgs,
    });
    console.log("   ✅ VaultProofNFT verified");
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("   ℹ️  Already verified");
    } else {
      console.log("   ❌ Error:", error.message);
    }
  }

  // 3. Verify ComplianceRegistry
  console.log("\n3️⃣  Verifying ComplianceRegistry...");
  try {
    await run("verify:verify", {
      address: deployment.contracts.ComplianceRegistry.address,
      constructorArguments: deployment.contracts.ComplianceRegistry.constructorArgs,
    });
    console.log("   ✅ ComplianceRegistry verified");
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("   ℹ️  Already verified");
    } else {
      console.log("   ❌ Error:", error.message);
    }
  }

  // 4. Verify LaunchVault
  console.log("\n4️⃣  Verifying LaunchVault...");
  try {
    await run("verify:verify", {
      address: deployment.contracts.LaunchVault.address,
      constructorArguments: deployment.contracts.LaunchVault.constructorArgs,
    });
    console.log("   ✅ LaunchVault verified");
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("   ℹ️  Already verified");
    } else {
      console.log("   ❌ Error:", error.message);
    }
  }

  console.log("\n✅ Verification complete!\n");
  console.log("View on Polygonscan:");
  console.log(`  UNY:        https://polygonscan.com/address/${deployment.contracts.UNYToken.address}#code`);
  console.log(`  NFT:        https://polygonscan.com/address/${deployment.contracts.VaultProofNFT.address}#code`);
  console.log(`  Registry:   https://polygonscan.com/address/${deployment.contracts.ComplianceRegistry.address}#code`);
  console.log(`  LaunchVault: https://polygonscan.com/address/${deployment.contracts.LaunchVault.address}#code`);
  console.log("");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Verification failed:", error);
    process.exit(1);
  });
