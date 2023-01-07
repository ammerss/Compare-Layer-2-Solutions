require('dotenv').config()
import { ethers } from "hardhat";
const contract = require("../artifacts/contracts/Go.sol/Go.json");

////////////////////////     end of game result
////////////////////////     0 0 1 2 3 4 5 6 7 8
////////////////////////     0 0 0 0 0 1 0 0 0 0
////////////////////////     1 0 0 0 1 0 0 0 1 1
////////////////////////     2 1 1 1 1 0 0 1 0 0
////////////////////////     3 0 0 0 0 0 1 1 1 1
////////////////////////     4 2 2 2 2 2 2 2 2 0
////////////////////////     5 0 0 0 0 0 0 2 0 2
////////////////////////     6 1 0 0 0 0 0 0 0 0
////////////////////////     7 0 0 0 2 2 2 0 0 0
////////////////////////     8 1 0 0 0 0 0 0 0 0

async function main() {
  let cumGasUsed = ethers.BigNumber.from(0);
  const players = await ethers.getSigners();
  const p1 = players[0];
  const p2 = players[1]

  // 0. DEPLOY
  const turnLength = parseInt(process.env.GAME_TURN_LENGTH || '');
  const p1Nonce = parseInt(process.env.P1_NONCE || '');
  const stake = process.env.GAME_STAKE_ETH || ''

  const p1Commitment = ethers.utils.solidityKeccak256(["uint"], [p1Nonce]);
  const boardsize = 19; //choose board size here
  const bet = ethers.utils.parseEther(stake);

  const Q = await ethers.getContractFactory("queue");
  const Qlib = await Q.deploy();
  await Qlib.deployed();

  const Go = await ethers.getContractFactory("Go", {
    libraries: {
            queue: Qlib.address,
        },
    });

  let game = await Go.deploy(p2.address, turnLength, p1Commitment, boardsize, { value: bet });
  
  await game.deployed();
  console.log("Contract deployed at:", game.address);
  const contractAddress = game.address;

  // const contractAddress = process.env.CONTRACT_ADDRESS || ''
  


  // 1. JOIN GAME
  const p2Nonce = parseInt(process.env.P2_NONCE || '');
  game = new ethers.Contract(contractAddress, contract.abi, p2);
  const joinTx = await game.joinGame(p2Nonce, {value: bet});
  const joinRx = await joinTx.wait();
  console.log("P2 JOINED GAME");
  console.log("gasUsed:", joinRx.gasUsed.toString(), "| blockNumber:", joinRx.blockNumber, "| timestamp :", joinRx.timestamp );
  cumGasUsed = cumGasUsed.add(joinRx.gasUsed);


  // 2. START GAME   
  const gasLimit = parseInt(process.env.GAS_LIMIT || '');
  // const p1Nonce = parseInt(process.env.P1_NONCE || '');

  game = new ethers.Contract(contractAddress, contract.abi, p1);
  const startTx = await game.startGame(p1Nonce, {gasLimit: gasLimit});
  const startRx = await startTx.wait();
  const currentPlayerBit = await game.currentPlayer();
  console.log(`START GAME: currentPlayerBit is ${currentPlayerBit}`);
  console.log("gasUsed:", startRx.gasUsed.toString(), "| blockNumber:", startRx.blockNumber, "| timestamp :", startRx.timestamp );
  cumGasUsed = cumGasUsed.add(startRx.gasUsed);


  // 3. PLAY MOVE (LOOP)
  // in-order list of (x,y) coords of moves: moves[0] for P1, moves[1] for P2
  var moves = [[[2,0],[2,1],[2,2],[2,3],[1,3],[0,4],[6,0],[8,0],[3,5],[3,6],[3,7],[3,8],[2,6],[1,7],[1,8]],
               [[4,0],[4,1],[4,2],[4,3],[4,4],[4,5],[4,6],[4,7],[2,7],[2,8],[7,3],[7,4],[7,5],[5,6],[5,8]]];

  for (let i = 0; i < moves[0].length; i++) {
    for (let j = 1; j >= 0; j--){
        const playerIdx = j;
        const player = players[playerIdx];
        const squarex = moves[j][i][0];
        const squarey = moves[j][i][1];
        game = new ethers.Contract(contractAddress, contract.abi, player);
        
        const moveTx = await game.playMove(squarex,squarey, {gasLimit: gasLimit});
        const moveRx = await moveTx.wait();
        console.log("MOVE: ", i, "player:", j+1, "| played: ", squarex , squarey);
        console.log("gasUsed:", moveRx.gasUsed.toString(), "| blockNumber:", moveRx.blockNumber, "| timestamp :", moveRx.timestamp );
        cumGasUsed = cumGasUsed.add(moveRx.gasUsed);
    } 
  }

  // 4. PASS
  for (let i = 1; i >= 0; i--) {
    const player = players[i];
    game = new ethers.Contract(contractAddress, contract.abi, player);
    const passTx = await game.passMove();
    const passRx = await passTx.wait();
    console.log("PASS");
    console.log("gasUsed:", passRx.gasUsed.toString(), "| blockNumber:", passRx.blockNumber, "| timestamp :", passRx.timestamp );
    cumGasUsed = cumGasUsed.add(passRx.gasUsed);
  }

  const winner = await game.gameOutcome();
  const gameState = await game.gameState();
  console.log("Winner (from gameOutcome()): P" + winner, "GameState:", gameState);

  // 5. CLOSE GAME
  let p1Balance = await p1.getBalance()
  let p2Balance = await p2.getBalance()
  console.log("PRE CLOSE GAME:", "P1 balance:", p1Balance, "P2 balance:", p2Balance)

  const closeGameTx = await game.closeGame({gasLimit: gasLimit});
  const closeGameRx = await closeGameTx.wait();
  console.log("CLOSE GAME:");
  console.log("gasUsed:", closeGameRx.gasUsed.toString(), "| blockNumber:", closeGameRx.blockNumber, "| timestamp :", closeGameRx.timestamp );
  cumGasUsed = cumGasUsed.add(closeGameRx.gasUsed);

  p1Balance = await p1.getBalance()
  p2Balance = await p2.getBalance()
  console.log("POS CLOSE GAME:", "P1 balance:", p1Balance, "P2 balance:", p2Balance)
  console.log("P1 balance:", p1Balance);
  console.log("P2 balance:", p2Balance);
  
  console.log("cumGasUsed:", cumGasUsed.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});