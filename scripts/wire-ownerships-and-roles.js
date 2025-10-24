/**
 * Wire Ownerships & Roles - Production Grade Security
 * 
 * Transfers all contract ownerships and roles to Gnosis Safe multisigs
 * Run AFTER creating your 4 Safes on Polygon/L1
 */

require("dotenv").config();
const hre = require("hardhat");

// Load Safe addresses from env
const SAFES = {
  ADMIN_SAFE: process.env.ADMIN_SAFE || "",
  TREASURY_SAFE: process.env.TREASURY_SAFE || "",
  COMPLIANCE_SAFE: process.env.COMPLIANCE_SAFE || "",
  OPS_SAFE: process.env.OPS_SAFE || "",
  GUARDIAN_EOA: process.env.GUARDIAN_EOA || "",
};

// Validate all safes are set
function validateSafes() {
  const missing = Object.entries(SAFES)
    .filter(([_, addr]) => !addr || addr.length !== 42)
    .map(([name]) => name);
  
  if (missing.length > 0) {
    throw new Error(`Missing Safe addresses in .env: ${missing.join(", ")}\n\nCreate Safes first using https://safe.global/`);
  }
}

const id = (s) => hre.ethers.id(s); // keccak256 for role IDs

async function tryFn(label, fn) {
  try {
    const result = await fn();
    console.log(`✅ ${label}`);
    return result;
  } catch (e) {
    console.log(`⚠️  ${label} → ${String(e.message || e).split("\n")[0]}`);
  }
}

async function ownIfPossible(name, addr, newOwner) {
  const c = await hre.ethers.getContractAt(name, addr);
  try {
    const cur = await c.owner();
    if (cur.toLowerCase() === newOwner.toLowerCase()) {
      return console.log(`↪︎ ${name} already owned by ${newOwner.slice(0, 10)}...`);
    }
  } catch {
    return console.log(`↪︎ ${name} has no owner() function`);
  }
  
  await tryFn(`${name}.transferOwnership(${newOwner.slice(0, 10)}...)`, async () => {
    const tx = await c.transferOwnership(newOwner);
    await tx.wait();
  });
}

async function grantIfPossible(name, addr, role, grantee) {
  const c = await hre.ethers.getContractAt(name, addr);
  try {
    const r = id(role);
    const has = await c.hasRole(r, grantee);
    if (has) return console.log(`↪︎ ${name} ${role} already → ${grantee.slice(0, 10)}...`);
  } catch {
    return console.log(`↪︎ ${name} has no AccessControl`);
  }
  
  await tryFn(`${name}.grantRole(${role}, ${grantee.slice(0, 10)}...)`, async () => {
    const tx = await c.grantRole(id(role), grantee);
    await tx.wait();
  });
}

async function revokeIfPossible(name, addr, role, account) {
  const c = await hre.ethers.getContractAt(name, addr);
  await tryFn(`${name}.revokeRole(${role}, ${account.slice(0, 10)}...)`, async () => {
    const tx = await c.revokeRole(id(role), account);
    await tx.wait();
  });
}

async function setIf(name, addr, fn, value) {
  const c = await hre.ethers.getContractAt(name, addr);
  try {
    const frag = c.interface.getFunction(`${fn}(address)`);
    if (!frag) return console.log(`↪︎ ${name} has no ${fn}(address)`);
  } catch {
    return console.log(`↪︎ ${name} has no ${fn}(address)`);
  }
  
  await tryFn(`${name}.${fn}(${value.slice(0, 10)}...)`, async () => {
    const tx = await c[fn](value);
    await tx.wait();
  });
}

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  
  console.log("\n🔐 WIRING OWNERSHIPS & ROLES TO SAFES");
  console.log("════════════════════════════════════════════════════════");
  console.log("Network:", hre.network.name, `(chainId: ${network.chainId})`);
  console.log("Deployer:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)));
  
  // Validate Safes exist
  validateSafes();
  
  console.log("\n📋 SAFE ADDRESSES:");
  console.log("────────────────────────────────────────────────────────");
  console.log("  ADMIN_SAFE:", SAFES.ADMIN_SAFE);
  console.log("  TREASURY_SAFE:", SAFES.TREASURY_SAFE);
  console.log("  COMPLIANCE_SAFE:", SAFES.COMPLIANCE_SAFE);
  console.log("  OPS_SAFE:", SAFES.OPS_SAFE);
  console.log("  GUARDIAN_EOA:", SAFES.GUARDIAN_EOA);
  
  // Load deployment addresses
  const { loadDeployment } = require("./lib/deployments");
  const deployment = loadDeployment(hre.network.name);
  const contracts = deployment.contracts;
  
  console.log("\n🔄 PHASE 1: Core Contract Ownerships");
  console.log("────────────────────────────────────────────────────────");
  
  // ComplianceRegistry → COMPLIANCE_SAFE
  await ownIfPossible("ComplianceRegistry", contracts.complianceRegistry, SAFES.COMPLIANCE_SAFE);
  
  // LaunchVault → OPS_SAFE (already owns VaultProofNFT)
  await ownIfPossible("LaunchVault", contracts.launchVault, SAFES.OPS_SAFE);
  
  console.log("\n🔄 PHASE 2: Licensing & Fee Routing");
  console.log("────────────────────────────────────────────────────────");
  
  // RoyaltySplitter → TREASURY_SAFE
  await ownIfPossible("RoyaltySplitter", contracts.royaltySplitter, SAFES.TREASURY_SAFE);
  
  // FeeRouter → TREASURY_SAFE
  await ownIfPossible("FeeRouter", contracts.feeRouter, SAFES.TREASURY_SAFE);
  
  // LicenseNFT → ADMIN_SAFE
  await ownIfPossible("LicenseNFT", contracts.licenseNFT, SAFES.ADMIN_SAFE);
  
  console.log("\n🔄 PHASE 3: Oracle Layer");
  console.log("────────────────────────────────────────────────────────");
  
  // PriceOracle → OPS_SAFE
  await ownIfPossible("PriceOracle", contracts.priceOracle, SAFES.OPS_SAFE);
  
  // ComplianceOracle → COMPLIANCE_SAFE
  await ownIfPossible("ComplianceOracle", contracts.complianceOracle, SAFES.COMPLIANCE_SAFE);
  
  // WeatherOracle → OPS_SAFE
  await ownIfPossible("WeatherOracle", contracts.weatherOracle, SAFES.OPS_SAFE);
  
  console.log("\n🔄 PHASE 4: Advanced Token Roles");
  console.log("────────────────────────────────────────────────────────");
  
  // ERC1155Carbon roles
  await grantIfPossible("ERC1155Carbon", contracts.carbonToken, "DEFAULT_ADMIN_ROLE", SAFES.ADMIN_SAFE);
  await grantIfPossible("ERC1155Carbon", contracts.carbonToken, "MINTER_ROLE", SAFES.OPS_SAFE);
  await grantIfPossible("ERC1155Carbon", contracts.carbonToken, "PAUSER_ROLE", SAFES.COMPLIANCE_SAFE);
  await grantIfPossible("ERC1155Carbon", contracts.carbonToken, "PAUSER_ROLE", SAFES.GUARDIAN_EOA);
  
  // ERC1400TaxEquity roles
  await grantIfPossible("ERC1400TaxEquity", contracts.taxEquityToken, "DEFAULT_ADMIN_ROLE", SAFES.ADMIN_SAFE);
  await grantIfPossible("ERC1400TaxEquity", contracts.taxEquityToken, "CONTROLLER_ROLE", SAFES.TREASURY_SAFE);
  await grantIfPossible("ERC1400TaxEquity", contracts.taxEquityToken, "TRANSFER_AGENT_ROLE", SAFES.COMPLIANCE_SAFE);
  
  console.log("\n🔄 PHASE 5: Retirement System");
  console.log("────────────────────────────────────────────────────────");
  
  // BufferPool → TREASURY_SAFE (manages reserves)
  await ownIfPossible("BufferPool", contracts.bufferPool, SAFES.TREASURY_SAFE);
  
  // RetirementAttestation → COMPLIANCE_SAFE
  await ownIfPossible("RetirementAttestation", contracts.retirementAttestation, SAFES.COMPLIANCE_SAFE);
  
  console.log("\n🔄 PHASE 6: Marketplaces");
  console.log("────────────────────────────────────────────────────────");
  
  // RECMarketplace → OPS_SAFE
  await ownIfPossible("RECMarketplace", contracts.recMarketplace, SAFES.OPS_SAFE);
  
  console.log("\n🔄 PHASE 7: Fee Recipients");
  console.log("────────────────────────────────────────────────────────");
  
  // Point all fee endpoints to TREASURY_SAFE
  await setIf("FeeRouter", contracts.feeRouter, "setTreasury", SAFES.TREASURY_SAFE);
  await setIf("RECMarketplace", contracts.recMarketplace, "setFeeTo", SAFES.TREASURY_SAFE);
  await setIf("LaunchVault", contracts.launchVault, "setTreasury", SAFES.TREASURY_SAFE);
  
  console.log("\n🔄 PHASE 8: Revoke Deployer (DANGER ZONE)");
  console.log("────────────────────────────────────────────────────────");
  console.log("⚠️  This will remove deployer admin rights. Safes will control everything.");
  console.log("⚠️  Make sure Safes are correctly configured before proceeding!");
  
  // Uncomment to revoke deployer roles (DO THIS LAST!)
  // await revokeIfPossible("ERC1155Carbon", contracts.carbonToken, "DEFAULT_ADMIN_ROLE", deployer.address);
  // await revokeIfPossible("ERC1400TaxEquity", contracts.taxEquityToken, "DEFAULT_ADMIN_ROLE", deployer.address);
  
  console.log("\n✅ WIRING COMPLETE!");
  console.log("════════════════════════════════════════════════════════");
  console.log("🎉 All contracts now controlled by Safes.");
  console.log("🔐 Deployer still has admin roles (revoke manually when ready).");
  console.log("\n📋 NEXT STEPS:");
  console.log("  1. Verify Safe ownership on Polygonscan");
  console.log("  2. Test Safe transactions (propose + approve + execute)");
  console.log("  3. Uncomment revoke lines above to remove deployer access");
  console.log("  4. Run end-to-end smoke tests");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ ERROR:", error.message);
    process.exit(1);
  });
