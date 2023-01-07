const contract = require("../artifacts/contracts/Go.sol/Go.json");

async function main() {
  const contractAddress = process.env.CONTRACT_ADDRESS || ''

  const playerIdx = parseInt(process.env.PLAYER || '') - 1;
  const squarex = parseInt(process.env.SQUAREX || '');
  const squarey = parseInt(process.env.SQUAREY || '');
  const players = await ethers.getSigners();
  const player = players[playerIdx];


  const game = new ethers.Contract(contractAddress, contract.abi, player);
  await game.playMove(squarex,squarey);
  console.log("played: ", squarex , squarey);
}

main();

