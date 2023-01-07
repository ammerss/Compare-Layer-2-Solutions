const contract = require("../artifacts/contracts/Go.sol/Go.json");





async function main() {
    const [_, p2] = await ethers.getSigners();
    const contractAddress = process.env.CONTRACT_ADDRESS || ''
    const gameContract = new ethers.Contract(contractAddress, contract.abi, p2);

    for (let i = 0; i < 2; i++) {
        const player = await gameContract.players(i);
        console.log(`Player ${i}: ${player}`);
    };
    const currentPlayer = await gameContract.currentPlayer() + 1;
    console.log("currentPlayer: " + currentPlayer);

    const turnLength = await gameContract.turnLength();
    const turnDeadline = await gameContract.turnDeadline();
    console.log("turnLength: " + turnLength);
    console.log("turnDeadline: " + turnDeadline);
    const blockNumber = await ethers.provider.getBlockNumber();
    console.log("block.number: " + blockNumber);

    const p1Commitment = await gameContract.p1Commitment();
    const p2Nonce = await gameContract.p2Nonce();
    console.log("p1Commitment: " + p1Commitment);
    console.log("p2Nonce: " + p2Nonce);

    console.log("board state:");
    for (let i = 0; i < 9; i++) {
        for (let j = 0; j < 9; j++) {
            const tile = await gameContract.board(i,j);
            process.stdout.write(tile + " ");
        }
        process.stdout.write("\n");
    }

    const gameState = await gameContract.checkGameOver();
    console.log("gameState: " + gameState);
  }
main();