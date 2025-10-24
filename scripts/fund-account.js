const hre = require("hardhat");

/**
 * Fund an address on Unykorn L1 with native UNYETH.
 * Usage:
 *   DEPLOYER_PK=... npx hardhat run scripts/fund-account.js --network unykorn -- <recipient> <amount>
 * Example:
 *   $env:DEPLOYER_PK="<hex_without_0x>" ; npm run fund:unykorn -- 0xYourMetaMaskAddress 10
 */
async function main() {
  const [recipient, amountStr] = process.argv.slice(2);
  if (!recipient || !amountStr) {
    console.error("Usage: npm run fund:unykorn -- <recipient> <amountInUNYETH>");
    process.exit(1);
  }

  // Build wallet from DEPLOYER_PK or PRIVATE_KEY (without 0x)
  const pk = process.env.DEPLOYER_PK || process.env.PRIVATE_KEY;
  if (!pk) {
    throw new Error("DEPLOYER_PK or PRIVATE_KEY env var is required to sign the funding transaction");
  }

  const provider = hre.ethers.provider;
  const wallet = new hre.ethers.Wallet(pk.startsWith("0x") ? pk : "0x" + pk, provider);

  const network = await provider.getNetwork();
  if (Number(network.chainId) !== 7777) {
    console.warn(`Warning: chainId is ${network.chainId}, expected 7777 for Unykorn L1`);
  }

  const feeData = await provider.getFeeData();
  const overrides = {};
  if (feeData.maxFeePerGas) overrides.maxFeePerGas = feeData.maxFeePerGas;
  if (feeData.maxPriorityFeePerGas) overrides.maxPriorityFeePerGas = feeData.maxPriorityFeePerGas;

  const amount = hre.ethers.parseEther(amountStr);

  console.log("\nFunding address on Unykorn L1...");
  console.log("Deployer:", wallet.address);
  console.log("Recipient:", recipient);
  console.log("Amount:", amountStr, "UNYETH");

  const before = await provider.getBalance(recipient);

  const tx = await wallet.sendTransaction({ to: recipient, value: amount, ...overrides });
  console.log("  ↪ tx:", tx.hash);
  const receipt = await tx.wait();
  console.log("  ✓ confirmed in block", receipt.blockNumber);

  const after = await provider.getBalance(recipient);
  console.log("Balance before:", hre.ethers.formatEther(before));
  console.log("Balance after: ", hre.ethers.formatEther(after));
  console.log("Done.\n");
}

main().catch((e) => { console.error(e); process.exit(1); });
