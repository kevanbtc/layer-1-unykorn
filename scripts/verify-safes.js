/**
 * Verify Production Safes
 * Check that all 4 Safes exist and have correct configuration
 */

const { ethers } = require("hardhat");

// Minimal Safe interface (just what we need)
const SAFE_ABI = [
  "function getOwners() view returns (address[])",
  "function getThreshold() view returns (uint256)",
  "function isOwner(address owner) view returns (bool)",
  "function nonce() view returns (uint256)"
];

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  console.log("\n=================================================");
  console.log("   VERIFY PRODUCTION SAFES");
  console.log("=================================================\n");

  console.log(`Network: ${network.name} (chainId ${chainId})`);
  console.log(`Deployer: ${deployer.address}\n`);

  const safes = {
    ADMIN_SAFE: {
      address: process.env.ADMIN_SAFE,
      expectedThreshold: 3,
      name: "ADMIN_SAFE"
    },
    TREASURY_SAFE: {
      address: process.env.TREASURY_SAFE,
      expectedThreshold: 2,
      name: "TREASURY_SAFE"
    },
    COMPLIANCE_SAFE: {
      address: process.env.COMPLIANCE_SAFE,
      expectedThreshold: 2,
      name: "COMPLIANCE_SAFE"
    },
    OPS_SAFE: {
      address: process.env.OPS_SAFE,
      expectedThreshold: 2,
      name: "OPS_SAFE"
    }
  };

  let allValid = true;

  for (const [name, config] of Object.entries(safes)) {
    console.log(`\n${"=".repeat(60)}`);
    console.log(`${name}: ${config.address}`);
    console.log(`${"=".repeat(60)}`);

    if (!config.address || config.address.startsWith("0x...")) {
      console.log(`❌ NOT CONFIGURED - Update .env with Safe address`);
      allValid = false;
      continue;
    }

    try {
      // Check if contract exists
      const code = await ethers.provider.getCode(config.address);
      if (code === "0x") {
        console.log(`❌ NOT DEPLOYED - No contract found at this address`);
        allValid = false;
        continue;
      }

      // Connect to Safe
      const safe = new ethers.Contract(config.address, SAFE_ABI, deployer);

      // Get owners
      const owners = await safe.getOwners();
      console.log(`\n✅ Safe exists (${owners.length} owners)`);

      // Get threshold
      const threshold = await safe.getThreshold();
      console.log(`✅ Threshold: ${threshold}-of-${owners.length}`);

      if (Number(threshold) !== config.expectedThreshold) {
        console.log(`⚠️  WARNING: Expected ${config.expectedThreshold}, got ${threshold}`);
        allValid = false;
      }

      // List owners
      console.log(`\nOwners:`);
      owners.forEach((owner, i) => {
        console.log(`  ${i + 1}. ${owner}`);
      });

      // Get nonce (transaction count)
      const nonce = await safe.nonce();
      console.log(`\nTransaction count: ${nonce}`);

      // Check balance
      const balance = await ethers.provider.getBalance(config.address);
      console.log(`Balance: ${ethers.formatEther(balance)} ${chainId === 7777 ? "UNYETH" : "MATIC"}`);

    } catch (error) {
      console.log(`❌ ERROR: ${error.message}`);
      allValid = false;
    }
  }

  // Check GUARDIAN_EOA
  console.log(`\n${"=".repeat(60)}`);
  console.log(`GUARDIAN_EOA: ${process.env.GUARDIAN_EOA || "NOT SET"}`);
  console.log(`${"=".repeat(60)}`);

  if (!process.env.GUARDIAN_EOA || process.env.GUARDIAN_EOA === "0x9Dc918deBA2d3fc7128A59852b6699CCb2dC0EDB") {
    console.log(`⚠️  WARNING: GUARDIAN_EOA is still set to deployer`);
    console.log(`   Update to a hardware wallet in cold storage!`);
  } else {
    const balance = await ethers.provider.getBalance(process.env.GUARDIAN_EOA);
    console.log(`✅ GUARDIAN_EOA configured`);
    console.log(`Balance: ${ethers.formatEther(balance)} ${chainId === 7777 ? "UNYETH" : "MATIC"}`);
  }

  // Summary
  console.log(`\n${"=".repeat(60)}`);
  console.log(`SUMMARY`);
  console.log(`${"=".repeat(60)}`);

  if (allValid) {
    console.log(`\n✅ ALL SAFES VERIFIED`);
    console.log(`\nReady to deploy contracts and wire ownerships:`);
    console.log(`  npm run deploy:energy:${chainId === 7777 ? "unykorn" : "polygon"}`);
    console.log(`  npm run wire:safes:${chainId === 7777 ? "unykorn" : "polygon"}`);
  } else {
    console.log(`\n❌ SOME SAFES HAVE ISSUES`);
    console.log(`\nFix the issues above before proceeding.`);
  }

  console.log("");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
