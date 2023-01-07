const contract = require("../artifacts/contracts/TicTacToe.sol/TicTacToe.json");

async function main() {
    const contractAddress = process.env.CONTRACT_ADDRESS || ''

    const playerIdx = parseInt(process.env.PLAYER || '') - 1;
    const players = await ethers.getSigners();
    const player = players[playerIdx];

    const gasLimit = parseInt(process.env.GAS_LIMIT || '');

    const gameContract = new ethers.Contract(contractAddress, contract.abi, player);

    console.log("Player balance before close game: ", (await player.getBalance()).toString());
    await gameContract.closeGame({gasLimit: gasLimit});
    console.log("Player balance after close game: ", (await player.getBalance()).toString());
  }

main();