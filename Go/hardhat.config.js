require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
const { POLGYGON_ALCHEMY_API_URL, P1_PRIVATE_KEY, P1_PRIVKEY, P2_PRIVKEY, ALCHEMY_API_KEY } = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.17",
  networks: {
    mumbai: {
      url: POLGYGON_ALCHEMY_API_URL,
      accounts: [`0x${P1_PRIVATE_KEY}`, `${P2_PRIVKEY}`],
      gas: 2100000,
      gasPrice: 8000000000,
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${P1_PRIVKEY}`, `${P2_PRIVKEY}`]
    },
    arbitrum_goerli: {
      url: process.env['ARBITRUM_GOERLI_L2RPC'],
      accounts: [`${P1_PRIVKEY}`, `${P2_PRIVKEY}`],
    },
  }
};