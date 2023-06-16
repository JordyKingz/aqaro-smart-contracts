import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";
import "@nomicfoundation/hardhat-toolbox";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  // @ts-ignore
  allowUnlimitedContractSize: true,
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    sepolia: {
      url: process.env.SEPOLIA_URL,
      // @ts-ignore
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
};

export default config;
