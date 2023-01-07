const contract = require("../artifacts/contracts/TicTacToe.sol/TicTacToe.json");

async function main() {
    const [p1] = await ethers.getSigners();
    const contractAddress = process.env.CONTRACT_ADDRESS || ''
    const gasLimit = parseInt(process.env.GAS_LIMIT || '');
    const p1Nonce = parseInt(process.env.P1_NONCE || '');

    const gameContract = new ethers.Contract(contractAddress, contract.abi, p1);
    const startGame = await gameContract.startGame(p1Nonce, {gasLimit: gasLimit});
    await startGame.wait();

    const currentPlayer = await gameContract.currentPlayer() + 1;
    const turnDeadline = await gameContract.turnDeadline();
    console.log(`startGame success: currentPlayer is ${currentPlayer}, turnDeadline is ${turnDeadline}`);
  }

main();