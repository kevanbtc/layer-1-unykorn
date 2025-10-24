import { ethers } from "hardhat";

async function main() {
  console.log("🚀 Deploying Greeter to Unykorn L1...\n");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying from account:", deployer.address);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "ETH\n");

  // Deploy the Greeter contract
  const initialGreeting = "Hello from Unykorn L1! Chain ID 7777 🦄";
  
  console.log("⏳ Deploying Greeter contract...");
  const Greeter = await ethers.getContractFactory("Greeter");
  const greeter = await Greeter.deploy(initialGreeting);
  
  await greeter.waitForDeployment();
  const address = await greeter.getAddress();
  
  console.log("\n✅ Greeter deployed successfully!");
  console.log("📍 Contract address:", address);
  console.log("💬 Initial greeting:", initialGreeting);
  
  // Verify deployment by calling greet()
  console.log("\n🔍 Verifying deployment...");
  const greeting = await greeter.greet();
  console.log("✓ Contract greet() returns:", greeting);
  
  const info = await greeter.getInfo();
  console.log("✓ Owner:", info[1]);
  console.log("✓ Greeting count:", info[2].toString());
  
  // Test updating greeting
  console.log("\n📝 Testing setGreeting()...");
  const tx = await greeter.setGreeting("Unykorn L1 is live! 🔥");
  await tx.wait();
  
  const newGreeting = await greeter.greet();
  console.log("✓ New greeting:", newGreeting);
  
  const newInfo = await greeter.getInfo();
  console.log("✓ Updated count:", newInfo[2].toString());
  
  console.log("\n" + "=".repeat(60));
  console.log("🎉 DEPLOYMENT COMPLETE!");
  console.log("=".repeat(60));
  console.log("\n📋 Summary:");
  console.log("   Contract: Greeter");
  console.log("   Address:", address);
  console.log("   Network: Unykorn L1 (Chain ID 7777)");
  console.log("   Deployer:", deployer.address);
  console.log("\n🔗 Interact with your contract:");
  console.log(`   const greeter = await ethers.getContractAt("Greeter", "${address}");`);
  console.log(`   await greeter.greet();`);
  console.log(`   await greeter.setGreeting("Your message");`);
  console.log("\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
