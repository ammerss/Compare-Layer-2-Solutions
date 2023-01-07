require('dotenv').config()
import { ethers } from "hardhat";
const contract = require("../artifacts/contracts/StateChannel.sol/StateChannel.json");

async function main() {
    let cumGasUsed = ethers.BigNumber.from(0);
    const [p1, p2] = await ethers.getSigners();
    const challengeLength = parseInt(process.env.GAME_CHALLENGE_LENGTH || '');
    const p1Nonce = parseInt(process.env.P1_NONCE || '');
    const stake = process.env.GAME_STAKE_ETH || ''

    const p1Commitment = ethers.utils.solidityKeccak256(["uint"], [p1Nonce]);
    const bet = ethers.utils.parseEther(stake);
    
    const StateChannel = await ethers.getContractFactory("StateChannel");
    const game = await StateChannel.deploy(p2.address, challengeLength, p1Commitment, { value: bet });
    const contractRx = await game.deployTransaction.wait();
    console.log("CONTRACT DEPLOYED AT:", game.address);
    console.log("gasUsed:", contractRx.gasUsed.toString(), "| blockNumber:", contractRx.blockNumber, "| transactionHash:", contractRx.transactionHash);
    cumGasUsed = cumGasUsed.add(contractRx.gasUsed);

    // 1. JOIN GAME
    // await new Promise(r => setTimeout(r, 2000));

    const p2Nonce = parseInt(process.env.P2_NONCE || '');
    const joinGameTx = await game.connect(p2).joinGame(p2Nonce, {value: bet});
    const joinGameRx = await joinGameTx.wait();
    console.log("JOIN GAME:");
    console.log("gasUsed:", joinGameRx.gasUsed.toString(), "| blockNumber:", joinGameRx.blockNumber, "| transactionHash:", joinGameRx.transactionHash);
    cumGasUsed = cumGasUsed.add(joinGameRx.gasUsed);

    // 2. START GAME
    // await new Promise(r => setTimeout(r, 2000));

    const gasLimit = parseInt(process.env.GAS_LIMIT || '');
    const startGameTx = await game.startGame(p1Nonce, {gasLimit: gasLimit});
    const startGameRx = await startGameTx.wait();
    const currentPlayerBit = await game.currentPlayerBit();
    console.log(`START GAME: currentPlayerBit is ${currentPlayerBit}`);
    console.log("gasUsed:", startGameRx.gasUsed.toString(), "| blockNumber:", startGameRx.blockNumber, "| transactionHash:", startGameRx.transactionHash);
    cumGasUsed = cumGasUsed.add(startGameRx.gasUsed);

    // play game (we'll just skip this, it happens off-chain)

    // 3. CHALLENGE
    // const [p1, _] = await ethers.getSigners();
    // const contractAddress = process.env.CONTRACT_ADDRESS || ''
    // console.log(contractAddress);
    // const game = new ethers.Contract(contractAddress, contract.abi, p1);
    // const gameOutcome = await game.gameOutcome();
    // const gameState = await game.gameState();
    // console.log("gameOutcome:", gameOutcome, "| gameState: ", gameState);
    // // let currentPlayerBit = await game.currentPlayerBit();
    // let currentPlayerBit = (gameOutcome - 1) ^ 0x1;

    // await new Promise(r => setTimeout(r, 2000));

    const otherPlayerBit = currentPlayerBit ^ 0x1;
    const currentPlayer = (await ethers.getSigners())[currentPlayerBit];
    const otherPlayer = (await ethers.getSigners())[otherPlayerBit];
    const currentPlayerVal = currentPlayerBit + 1;
    const otherPlayerVal = otherPlayerBit + 1;
    const prevState = [
        currentPlayerVal, otherPlayerVal, currentPlayerVal,
        otherPlayerVal, currentPlayerVal, otherPlayerVal,
        0, 0, 0,
    ];
    const winningMoves = [2, 4, 6];
    const abi = ethers.utils.defaultAbiCoder;
    const encodedPrevState = abi.encode(["uint8[9]"], [prevState]);
    const encodedWinningMoves = abi.encode(["uint8[3]"], [winningMoves]);
    const hashedPrevState : string = ethers.utils.solidityKeccak256(["uint8[9]"], [prevState]);
    const signedPrevState : string = await otherPlayer.signMessage(ethers.utils.arrayify(hashedPrevState));

    const challengeTx = await game.connect(currentPlayer).challenge(currentPlayerVal, encodedPrevState, signedPrevState, encodedWinningMoves);
    const challengeRx = await challengeTx.wait();
    console.log("CHALLENGE:");
    console.log("gameOutcome:", await game.gameOutcome(), "| gameState: ", await game.gameState());
    console.log("gasUsed:", challengeRx.gasUsed.toString(), "| blockNumber:", challengeRx.blockNumber, "| transactionHash:", challengeRx.transactionHash);
    cumGasUsed = cumGasUsed.add(challengeRx.gasUsed);

    // // 4. CLOSE GAME
    // await new Promise(r => setTimeout(r, 2000));

    let p1Balance = await p1.getBalance()
    let p2Balance = await p2.getBalance()
    console.log("PRE CLOSE GAME:", "P1 balance:", p1Balance, "P2 balance:", p2Balance)

    const closeGameTx = await game.connect(currentPlayer).closeGame();
    const closeGameRx = await closeGameTx.wait();
    console.log("CLOSE GAME:");
    console.log("gasUsed:", closeGameRx.gasUsed.toString(), "| blockNumber:", closeGameRx.blockNumber, "| transactionHash:", closeGameRx.transactionHash);
    cumGasUsed = cumGasUsed.add(closeGameRx.gasUsed);

    p1Balance = await p1.getBalance()
    p2Balance = await p2.getBalance()
    console.log("POS CLOSE GAME:", "P1 balance:", p1Balance, "P2 balance:", p2Balance)
    console.log("P1 balance:", p1Balance);
    console.log("P2 balance:", p2Balance);
    
    console.log("cumGasUsed:", cumGasUsed.toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });