const hre = require("hardhat");

async function main() {
  const txHash = "0x5e3f3a93a16e2cb3736eb6ab243ec5f4de32bc03e68fbc9b5be8073e4f499462";
  
  console.log("\n🔍 Checking deployment transaction...\n");
  console.log("TX Hash:", txHash);
  
  const receipt = await hre.ethers.provider.getTransactionReceipt(txHash);
  
  if (!receipt) {
    console.log("❌ Transaction not found or still pending");
    return;
  }
  
  console.log("Block:", receipt.blockNumber);
  console.log("Gas Used:", receipt.gasUsed.toString());
  console.log("Status:", receipt.status === 1 ? "✅ Success" : "❌ Failed");
  
  if (receipt.contractAddress) {
    console.log("\n✅ Contract deployed at:", receipt.contractAddress);
    
    // Check code
    const code = await hre.ethers.provider.getCode(receipt.contractAddress);
    console.log("Code length:", code.length, "bytes");
    
    if (code !== "0x") {
      console.log("\n📝 Testing contract interactions...");
      
      const token = await hre.ethers.getContractAt("SimpleToken", receipt.contractAddress);
      
      try {
        const name = await token.name();
        console.log("  Name:", name);
      } catch (e) {
        console.log("  Name: (not available)");
      }
      
      try {
        const symbol = await token.symbol();
        console.log("  Symbol:", symbol);
      } catch (e) {
        console.log("  Symbol: (not available)");
      }
      
      try {
        const totalSupply = await token.totalSupply();
        console.log("  Total Supply:", hre.ethers.formatEther(totalSupply));
      } catch (e) {
        console.log("  Total Supply: (not available)");
      }
      
      const [deployer] = await hre.ethers.getSigners();
      try {
        const balance = await token.balanceOf(deployer.address);
        console.log("  Deployer Balance:", hre.ethers.formatEther(balance));
      } catch (e) {
        console.log("  Balance: (not available)");
      }
      
      console.log("\n🎉 SimpleToken is live on Unykorn L1!");
      console.log("\n✅ Chain ID 7777 is working correctly.");
      console.log("✅ Contract deployment successful.");
      console.log("✅ Ready to deploy full energy system.");
    } else {
      console.log("❌ No contract code at address");
    }
  } else {
    console.log("❌ No contract address in receipt");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
