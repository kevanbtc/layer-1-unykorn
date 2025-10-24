const hre = require("hardhat");

async function main() {
  const { network, ethers } = hre;
  if (network.name !== "unykorn") {
    console.log(`Tip: pass --network unykorn (current: ${network.name})`);
  }
  const [signer] = await ethers.getSigners();
  const bal = await ethers.provider.getBalance(signer.address);
  const feeData = await ethers.provider.getFeeData();
  console.log("Network:", network.name, network.config.chainId);
  console.log("Deployer:", signer.address);
  console.log("Balance:", ethers.formatEther(bal), "UNYETH");
  console.log("FeeData:", {
    gasPrice: feeData.gasPrice?.toString?.() ?? null,
    maxFeePerGas: feeData.maxFeePerGas?.toString?.() ?? null,
    maxPriorityFeePerGas: feeData.maxPriorityFeePerGas?.toString?.() ?? null,
  });
}

main().catch((e) => { console.error(e); process.exit(1); });
