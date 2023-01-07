require('dotenv').config()
import { ethers } from "hardhat";

async function main() {
  const [p1, p2] = await ethers.getSigners();
  console.log(
    "Deploying contract using account:", p1.address);
  console.log("Account balance:", (await p1.getBalance()).toString());

  const turnLength = parseInt(process.env.GAME_TURN_LENGTH || '');
  const p1Nonce = parseInt(process.env.P1_NONCE || '');
  const stake = process.env.GAME_STAKE_ETH || ''

  const p1Commitment = ethers.utils.solidityKeccak256(["uint"], [p1Nonce]);
  const bet = ethers.utils.parseEther(stake);

  const TicTacToe = await ethers.getContractFactory("TicTacToe");
  const game = await TicTacToe.deploy(p2.address, turnLength, p1Commitment, { value: bet });
  await game.deployed(); // gets mined in a block(?)
  console.log("Contract deployed at:", game.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
