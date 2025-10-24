const hre = require("hardhat");

async function main() {
  console.log("\n🧪 SIMPLE TOKEN TEST ON UNYKORN L1\n");
  console.log("═".repeat(60));
  
  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  const feeData = await hre.ethers.provider.getFeeData();
  
  console.log("Network:", hre.network.name);
  console.log("ChainId:", network.chainId);
  console.log("Deployer:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(balance), "UNYETH");
  console.log("Gas Price:", feeData.gasPrice?.toString() ?? "auto");
  console.log("Max Fee:", feeData.maxFeePerGas?.toString() ?? "none");
  console.log("");
  
  // Deploy SimpleToken
  console.log("1️⃣  Deploying SimpleToken...");
  const SimpleToken = await hre.ethers.getContractFactory("SimpleToken");
  
  // Explicit fee overrides
  const overrides = {};
  if (feeData.maxFeePerGas) {
    overrides.maxFeePerGas = feeData.maxFeePerGas;
    overrides.maxPriorityFeePerGas = feeData.maxPriorityFeePerGas ?? 0n;
  } else if (feeData.gasPrice) {
    overrides.gasPrice = feeData.gasPrice;
  }
  
  const token = await SimpleToken.deploy(overrides);
  console.log("   Deploying... tx:", token.deploymentTransaction().hash);
  
  await token.waitForDeployment();
  const address = await token.getAddress();
  console.log("   ✅ Deployed at:", address);
  
  // Check initial balance
  console.log("\n2️⃣  Checking deployer balance...");
  const deployerBalance = await token.balanceOf(deployer.address);
  console.log("   Balance:", hre.ethers.formatEther(deployerBalance), "TEST");
  
  // Mint some tokens
  console.log("\n3️⃣  Minting 100 TEST tokens...");
  const mintTx = await token.mint(deployer.address, hre.ethers.parseEther("100"), overrides);
  console.log("   Minting... tx:", mintTx.hash);
  
  const receipt = await mintTx.wait();
  console.log("   ✅ Minted! Block:", receipt.blockNumber);
  console.log("   Gas Used:", receipt.gasUsed.toString());
  
  // Check new balance
  const newBalance = await token.balanceOf(deployer.address);
  console.log("\n4️⃣  New balance:", hre.ethers.formatEther(newBalance), "TEST");
  
  // Transfer test
  console.log("\n5️⃣  Testing transfer to random address...");
  const recipient = "0x1234567890123456789012345678901234567890";
  const transferTx = await token.transfer(recipient, hre.ethers.parseEther("10"), overrides);
  console.log("   Transferring... tx:", transferTx.hash);
  
  const transferReceipt = await transferTx.wait();
  console.log("   ✅ Transferred! Block:", transferReceipt.blockNumber);
  
  const recipientBalance = await token.balanceOf(recipient);
  console.log("   Recipient balance:", hre.ethers.formatEther(recipientBalance), "TEST");
  
  console.log("\n" + "═".repeat(60));
  console.log("🎉 SUCCESS! Unykorn L1 is working!");
  console.log("═".repeat(60));
  console.log("\nContract Address:", address);
  console.log("Total Supply:", hre.ethers.formatEther(await token.totalSupply()), "TEST");
  console.log("Deployer Balance:", hre.ethers.formatEther(await token.balanceOf(deployer.address)), "TEST");
  console.log("");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ ERROR:", error.message);
    console.error(error);
    process.exit(1);
  });
