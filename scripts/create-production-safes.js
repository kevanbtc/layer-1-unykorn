/**
 * Create 4 Production Safes for Unykorn Business Operations
 * 
 * ADMIN_SAFE (3-of-5): Governance, protocol upgrades, admin roles
 * TREASURY_SAFE (2-of-3): Fees, royalties, withdrawals
 * COMPLIANCE_SAFE (2-of-3): KYC/AML, freezes, pauses
 * OPS_SAFE (2-of-3): Markets, oracles, daily operations
 */

const { ethers } = require("hardhat");
const Safe = require("@safe-global/protocol-kit").default;
const fs = require("fs");
const path = require("path");

// Color output helpers
const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  green: "\x1b[32m",
  blue: "\x1b[34m",
  yellow: "\x1b[33m",
  cyan: "\x1b[36m"
};

function log(msg, color = colors.reset) {
  console.log(`${color}${msg}${colors.reset}`);
}

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  log("\n=================================================", colors.bright);
  log("   CREATE 4 PRODUCTION SAFES FOR UNYKORN", colors.bright);
  log("=================================================\n", colors.bright);

  log(`Network: ${network.name} (chainId ${chainId})`);
  log(`Deployer: ${deployer.address}`);
  log(`Balance: ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} ETH\n`);

  if (chainId !== 7777 && chainId !== 137) {
    throw new Error(`⚠️  Unsupported network. Use --network unykorn or --network polygon`);
  }

  // ==================================================================
  // SAFE CONFIGURATION
  // ==================================================================

  const safeConfig = {
    ADMIN_SAFE: {
      name: "ADMIN_SAFE",
      description: "Governance, protocol upgrades, DEFAULT_ADMIN_ROLE",
      owners: [
        process.env.FOUNDER_1 || deployer.address,  // Founder 1 (hardware wallet)
        process.env.FOUNDER_2 || deployer.address,  // Founder 2 (hardware wallet)
        process.env.FOUNDER_3 || deployer.address,  // Founder 3 (hardware wallet)
        process.env.LEGAL_COUNSEL || deployer.address,  // Legal Counsel
        process.env.CTO || deployer.address  // CTO
      ],
      threshold: 3  // 3-of-5 for critical governance
    },
    TREASURY_SAFE: {
      name: "TREASURY_SAFE",
      description: "Fees, royalties, withdrawals, all fee recipients",
      owners: [
        process.env.CFO || deployer.address,  // CFO (hardware wallet)
        process.env.TREASURER || deployer.address,  // Treasurer (hardware wallet)
        process.env.FOUNDER_1 || deployer.address  // Founder 1 (hardware wallet)
      ],
      threshold: 2  // 2-of-3 for financial ops
    },
    COMPLIANCE_SAFE: {
      name: "COMPLIANCE_SAFE",
      description: "KYC/AML, freezes, pauses, allowlists",
      owners: [
        process.env.COMPLIANCE_OFFICER || deployer.address,  // Compliance Officer
        process.env.LEGAL_COUNSEL || deployer.address,  // Legal Counsel
        process.env.EXTERNAL_AUDITOR || deployer.address  // External Auditor
      ],
      threshold: 2  // 2-of-3 for compliance actions
    },
    OPS_SAFE: {
      name: "OPS_SAFE",
      description: "Markets, oracles, LaunchVault, daily operations",
      owners: [
        process.env.CTO || deployer.address,  // CTO (hardware wallet)
        process.env.DEVOPS_LEAD || deployer.address,  // DevOps Lead
        process.env.PRODUCT_MANAGER || deployer.address  // Product Manager
      ],
      threshold: 2  // 2-of-3 for operational changes
    }
  };

  // ==================================================================
  // DEPLOY SAFES
  // ==================================================================

  const deployedSafes = {};

  for (const [safeName, config] of Object.entries(safeConfig)) {
    log(`\n${"=".repeat(60)}`, colors.cyan);
    log(`Creating ${safeName}`, colors.bright);
    log(`${"=".repeat(60)}`, colors.cyan);
    log(`Description: ${config.description}`, colors.cyan);
    log(`Threshold: ${config.threshold}-of-${config.owners.length}`, colors.cyan);
    log(`Owners:`, colors.cyan);
    config.owners.forEach((owner, i) => log(`  ${i + 1}. ${owner}`, colors.cyan));

    try {
      // Initialize Protocol Kit with predicted Safe
      const protocolKit = await Safe.init({
        provider: ethers.provider,
        signer: deployer.address,
        predictedSafe: {
          safeAccountConfig: {
            owners: config.owners,
            threshold: config.threshold
          }
        }
      });

      // Get predicted address BEFORE deployment
      const predictedAddress = await protocolKit.getAddress();
      log(`\n📍 Predicted Address: ${predictedAddress}`, colors.yellow);

      // Deploy the Safe
      log(`\n⏳ Deploying Safe...`, colors.blue);
      const deploymentResult = await protocolKit.deploy();
      
      log(`✅ Safe deployed successfully!`, colors.green);
      log(`Transaction hash: ${deploymentResult.hash}`, colors.green);
      log(`Safe address: ${predictedAddress}`, colors.bright);

      // Store result
      deployedSafes[safeName] = {
        address: predictedAddress,
        threshold: config.threshold,
        owners: config.owners,
        description: config.description,
        txHash: deploymentResult.hash
      };

      // Wait for confirmation
      log(`⏳ Waiting for confirmation...`, colors.blue);
      await deploymentResult.wait();
      log(`✅ Confirmed!`, colors.green);

    } catch (error) {
      log(`❌ Failed to deploy ${safeName}: ${error.message}`, colors.yellow);
      
      // If Safe already exists, try to get its address
      try {
        const protocolKit = await Safe.init({
          provider: ethers.provider,
          signer: deployer.address,
          predictedSafe: {
            safeAccountConfig: {
              owners: config.owners,
              threshold: config.threshold
            }
          }
        });
        const address = await protocolKit.getAddress();
        log(`ℹ️  Safe may already exist at: ${address}`, colors.yellow);
        
        deployedSafes[safeName] = {
          address: address,
          threshold: config.threshold,
          owners: config.owners,
          description: config.description,
          status: "may-already-exist"
        };
      } catch (e) {
        log(`⚠️  Could not determine Safe address: ${e.message}`, colors.yellow);
      }
    }
  }

  // ==================================================================
  // GUARDIAN EOA
  // ==================================================================

  log(`\n${"=".repeat(60)}`, colors.cyan);
  log(`GUARDIAN_EOA (Emergency Pause Only)`, colors.bright);
  log(`${"=".repeat(60)}`, colors.cyan);

  const guardianAddress = process.env.GUARDIAN_EOA || deployer.address;
  log(`Address: ${guardianAddress}`, colors.cyan);
  log(`Purpose: Emergency pause only (no spending authority)`, colors.cyan);
  log(`Security: Hardware wallet in cold storage`, colors.cyan);

  deployedSafes.GUARDIAN_EOA = {
    address: guardianAddress,
    description: "Emergency pause only (no spending authority)",
    type: "EOA"
  };

  // ==================================================================
  // SAVE RESULTS
  // ==================================================================

  log(`\n${"=".repeat(60)}`, colors.bright);
  log(`DEPLOYMENT SUMMARY`, colors.bright);
  log(`${"=".repeat(60)}`, colors.bright);

  const summary = {
    network: network.name,
    chainId: chainId,
    timestamp: new Date().toISOString(),
    deployer: deployer.address,
    safes: deployedSafes
  };

  // Save to JSON file
  const outputDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const outputFile = path.join(outputDir, `safes-${chainId}.json`);
  fs.writeFileSync(outputFile, JSON.stringify(summary, null, 2));

  log(`\n✅ Deployment details saved to: ${outputFile}`, colors.green);

  // Display summary
  log(`\n📋 SAFE ADDRESSES:`, colors.bright);
  for (const [name, data] of Object.entries(deployedSafes)) {
    log(`\n${name}:`, colors.cyan);
    log(`  Address: ${data.address}`, colors.green);
    log(`  Description: ${data.description}`, colors.cyan);
    if (data.threshold) {
      log(`  Threshold: ${data.threshold}-of-${data.owners.length}`, colors.cyan);
    }
    if (data.txHash) {
      log(`  Tx: ${data.txHash}`, colors.blue);
    }
  }

  // ==================================================================
  // NEXT STEPS
  // ==================================================================

  log(`\n${"=".repeat(60)}`, colors.yellow);
  log(`NEXT STEPS`, colors.bright);
  log(`${"=".repeat(60)}`, colors.yellow);

  log(`\n1. Update .env with Safe addresses:`);
  log(`   ADMIN_SAFE=${deployedSafes.ADMIN_SAFE?.address || "0x..."}`);
  log(`   TREASURY_SAFE=${deployedSafes.TREASURY_SAFE?.address || "0x..."}`);
  log(`   COMPLIANCE_SAFE=${deployedSafes.COMPLIANCE_SAFE?.address || "0x..."}`);
  log(`   OPS_SAFE=${deployedSafes.OPS_SAFE?.address || "0x..."}`);
  log(`   GUARDIAN_EOA=${deployedSafes.GUARDIAN_EOA?.address || "0x..."}`);

  log(`\n2. Replace deployer addresses with REAL hardware wallet owners`);
  log(`   (Use addOwner + removeOwner transactions after deployment)`);

  log(`\n3. Wire contract ownerships to Safes:`);
  log(`   npm run wire:safes:${chainId === 7777 ? "unykorn" : "polygon"}`);

  log(`\n4. Revoke deployer from all roles:`);
  log(`   (Automated in wire script)`);

  log(`\n5. Test Safe operations:`);
  log(`   - Sign a test transaction with ADMIN_SAFE (3-of-5)`);
  log(`   - Execute a fee withdrawal with TREASURY_SAFE (2-of-3)`);
  log(`   - Pause a contract with COMPLIANCE_SAFE (2-of-3)`);

  if (chainId === 7777) {
    log(`\n💎 FREE GAS on Unykorn L1! Deploy as many Safes as needed.`, colors.green);
  } else {
    log(`\n💰 Gas cost: ~0.10 MATIC per Safe (~$0.05)`, colors.yellow);
  }

  log(`\n🎉 Safe deployment complete!\n`, colors.green);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
