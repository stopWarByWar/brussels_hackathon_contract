import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";
import "@nomicfoundation/hardhat-chai-matchers";
// import "@nomiclabs/hardhat-waffle";
import * as dotenv from "dotenv";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY as string;
// const PRIVATE_KEY1 = process.env.PRIVATE_KEY1 as string;
const ARB_SPEPOLIA = process.env.ARB_SPEPOLIA as string;
const API_KEY = process.env.API_KEY as string;

const config: HardhatUserConfig = {
  solidity:{
     version:"0.8.24",
     settings:{
      optimizer: {
        enabled: true,
        runs: 200,
    },
     }
  },
  typechain: {
    outDir: 'typechain-types',
    target: 'ethers-v6',
    alwaysGenerateOverloads: false, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    externalArtifacts: ['externalArtifacts/*.json'], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
    dontOverrideCompile: false // defaults to false
  },
  networks:{
    // localhost: {
    //   gasPrice: 1e12
    // },
    ["arbi-sepolia"]: {
      chainId: 421614,
      url: ARB_SPEPOLIA,
      accounts: [PRIVATE_KEY]
    }
  },
  etherscan:{
    apiKey: {
      "arbi-sepolia":API_KEY,
    },
    customChains: [
      {
        network: "arbi-sepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io/"
        }
      }
    ]
  }
};

export default config;
