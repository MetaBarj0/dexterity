import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";
import "hardhat-watcher";
import { HardhatUserConfig } from "hardhat/config";

import { vars } from "hardhat/config";

const ALCHEMY_API_KEY = vars.get("ALCHEMY_API_KEY");
const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");
const ETHERSCAN_API_KEY = vars.get("ETHERSCAN_API_KEY");

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: process.env.ENABLE_OPTIMIZER,
        runs: 999999,
      },
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
  },
  watcher: {
    compile: {
      tasks: ["compile"],
      files: ["./contracts"],
      verbose: true,
      clearOnStart: true,
    },
    test: {
      tasks: [
        {
          command: "test",
        },
      ],
      files: ["./test/**/*.ts", "./contracts/**/*.sol"],
      verbose: true,
      clearOnStart: true,
    },
  }
};

export default config;
