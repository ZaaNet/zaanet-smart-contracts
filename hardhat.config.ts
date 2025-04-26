import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const {ALCHEMY_API_KEY, PRIVATE_KEY, ETHERSCAN_API_KEY} = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    arbitrumSepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`]
    },
  },
  etherscan: {
    apiKey: {
      arbitrumSepolia: ETHERSCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "arbitrum-sepolia",
        chainId: 421613,
        urls: {
          apiURL: "https://api.arbiscan.io/api",
          browserURL: "https://testnet.arbiscan.io",
        },
      },
    ],
  },
};

export default config;
