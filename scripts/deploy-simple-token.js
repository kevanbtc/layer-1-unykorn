const hre = require("hardhat");

async function main() {
  console.log("\n🚀 DEPLOYING SIMPLE TOKEN ON UNYKORN L1\n");
  console.log("═".repeat(60));
  
  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  
  console.log("Network:", hre.network.name);
  console.log("ChainId:", Number(network.chainId));
  console.log("Deployer:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(balance), "UNYETH");
  
  // Get fee data
  const feeData = await hre.ethers.provider.getFeeData();
  console.log("\nFee Data:");
  console.log("  Gas Price:", feeData.gasPrice?.toString() ?? "null");
  console.log("  Max Fee:", feeData.maxFeePerGas?.toString() ?? "null");
  console.log("  Priority Fee:", feeData.maxPriorityFeePerGas?.toString() ?? "null");
  
  console.log("\n📦 Deploying SimpleToken...");
  
  const SimpleToken = await hre.ethers.getContractFactory("SimpleToken");
  
  let token, address;
  try {
    token = await SimpleToken.deploy();
    console.log("   TX Hash:", token.deploymentTransaction().hash);
    
    // Wait for deployment with timeout
    console.log("   Waiting for confirmation...");
    await token.waitForDeployment();
    address = await token.getAddress();
  } catch (error) {
    console.error("\n❌ Deployment error:", error.message);
    throw error;
  }
  
  console.log("✅ SimpleToken deployed:", address);
  
  // Verify it's actually deployed
  const code = await hre.ethers.provider.getCode(address);
  console.log("\n🔍 Contract Code Length:", code.length, "bytes");
  
  if (code === "0x") {
    throw new Error("Contract not deployed! Code is empty.");
  }
  
  // Try to interact
  console.log("\n📝 Reading contract state...");
  
  try {
    const name = await token.name();
    console.log("   Name:", name);
  } catch (e) {
    console.log("   Name: (no name function or call failed)");
  }
  
  try {
    const symbol = await token.symbol();
    console.log("   Symbol:", symbol);
  } catch (e) {
    console.log("   Symbol: (no symbol function or call failed)");
  }
  
  try {
    const totalSupply = await token.totalSupply();
    console.log("   Total Supply:", hre.ethers.formatEther(totalSupply));
  } catch (e) {
    console.log("   Total Supply: (no totalSupply function or call failed)");
  }
  
  try {
    const balance = await token.balanceOf(deployer.address);
    console.log("   Deployer Balance:", hre.ethers.formatEther(balance));
  } catch (e) {
    console.log("   Balance: (no balanceOf function or call failed)");
  }
  
  // Try to mint (if function exists)
  console.log("\n💰 Testing mint (if available)...");
  try {
    const mintAmount = hre.ethers.parseEther("1000");
    const tx = await token.mint(deployer.address, mintAmount);
    console.log("   Mint TX:", tx.hash);
    await tx.wait();
    
    const newBalance = await token.balanceOf(deployer.address);
    console.log("   ✅ New Balance:", hre.ethers.formatEther(newBalance));
  } catch (e) {
    console.log("   ⚠️  Mint not available or failed:", e.message.split('\n')[0]);
  }
  
  // Save deployment info
  const fs = require("fs");
  const path = require("path");
  
  const deploymentInfo = {
    network: hre.network.name,
    chainId: Number(network.chainId),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    block: await hre.ethers.provider.getBlockNumber(),
    contracts: {
      simpleToken: address
    }
  };
  
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  fs.mkdirSync(deploymentsDir, { recursive: true });
  fs.writeFileSync(
    path.join(deploymentsDir, `${hre.network.name}-simple.json`),
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log("\n💾 Saved deployment to: deployments/" + hre.network.name + "-simple.json");
  
  console.log("\n🎉 SUCCESS! Unykorn L1 is live and working.");
  console.log("═".repeat(60));
  console.log("\n✅ Next steps:");
  console.log("  1. Deploy full energy system: npm run deploy:energy:unykorn");
  console.log("  2. Wire Safes: npm run wire:safes:unykorn");
  console.log("  3. Add to MetaMask:");
  console.log("     - Network Name: Unykorn L1");
  console.log("     - RPC URL: http://127.0.0.1:8545");
  console.log("     - Chain ID: 7777");
  console.log("     - Currency: UNY");
  console.log("\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ DEPLOYMENT FAILED:");
    console.error(error);
    process.exit(1);
  });
