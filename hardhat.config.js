require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "unykorn", // 🎯 Unykorn L1 is now the mothership
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000000, // Max optimization for L1 (free gas, prioritize size)
      },
      viaIR: true,
    },
  },
  networks: {
    // 🧪 Localhost - Connect to external Hardhat node (for testing)
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337, // Besu dev mode chainId
      accounts: process.env.DEPLOYER_PK ? [process.env.DEPLOYER_PK] : [
        "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3",
        "0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f",
        "0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1"
      ],
      timeout: 60000,
    },
    
    // 🏠 Unykorn L1 - The Canonical Registry (FREE GAS)
    unykorn: {
      url: process.env.UNYKORN_RPC || "http://127.0.0.1:8555",
      chainId: 7777,
      accounts: process.env.DEPLOYER_PK ? [process.env.DEPLOYER_PK] : [
        "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3",
        "0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f",
        "0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1"
      ],
  // Let EIP-1559 fee data be auto-detected by the client (Besu reports basefee/priority)
      timeout: 60000,
    },
    
    // 💧 Polygon - Liquidity Layer (for DEX trading)
    polygon: {
      url: process.env.POLYGON_RPC || "https://polygon-rpc.com",
      chainId: 137,
      accounts: process.env.DEPLOYER_PK ? [process.env.DEPLOYER_PK] : [],
      gasPrice: "auto",
      timeout: 120000,
    },
    
    // Polygon Mumbai Testnet (for pre-mainnet testing)
    mumbai: {
      url: process.env.MUMBAI_RPC || "https://rpc-mumbai.maticvigil.com",
      chainId: 80001,
      accounts: process.env.DEPLOYER_PK ? [process.env.DEPLOYER_PK] : [],
      gasPrice: "auto",
    },
    
    // Production mainnet (Unykorn L1)
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "https://rpc.unykorn.com",
      chainId: 7777,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: "auto",
    },
  },
  
  etherscan: {
    apiKey: {
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
    },
  },
  
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  
  mocha: {
    timeout: 60000,
  },
  
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
};
