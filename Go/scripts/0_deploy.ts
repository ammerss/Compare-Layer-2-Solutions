// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
require('dotenv').config()
const { ethers } = require("hardhat");

async function main() {
    const [p1, p2] = await ethers.getSigners();
    console.log(
      "Deploying contracts with the account:",
      p1.address
    );
  console.log("Account balance:", (await p1.getBalance()).toString());
  console.log("p2 address:", p2.address);

  const turnLength = parseInt(process.env.GAME_TURN_LENGTH || '');
  const p1Nonce = parseInt(process.env.P1_NONCE || '');
  const stake = process.env.GAME_STAKE_ETH || ''

  const p1Commitment = ethers.utils.solidityKeccak256(["uint"], [p1Nonce]);
  const boardsize = 9; //choose board size here
  const bet = ethers.utils.parseEther(stake);

  const Q = await ethers.getContractFactory("queue");
  const Qlib = await Q.deploy();
  await Qlib.deployed();

  const Go = await ethers.getContractFactory("Go", {
    libraries: {
            queue: Qlib.address,
        },
    });

  const game = await Go.deploy(p2.address, turnLength, p1Commitment, boardsize, { value: bet });

  
  await game.deployed();
  console.log("Contract deployed at:", game.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
