require('dotenv').config()

import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
const { POLGYGON_ALCHEMY_API_URL,POLYGON_P1_PRIVKEY} = process.env;
const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`${process.env.P1_PRIVKEY}`, `${process.env.P2_PRIVKEY}`]
    },
    arbitrum_goerli: {
      url: process.env['ARBITRUM_GOERLI_L2RPC'],
      accounts: [`${process.env.P1_PRIVKEY}`, `${process.env.P2_PRIVKEY}`],

    },
    mumbai : {
      url: POLGYGON_ALCHEMY_API_URL,
      accounts: [`0x${POLYGON_P1_PRIVKEY}`,`${process.env.P2_PRIVKEY}`],
      gas: 2100000,
      gasPrice: 8000000000,
    }
    

  }
};

export default config;
