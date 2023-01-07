const contract = require("../artifacts/contracts/TicTacToe.sol/TicTacToe.json");

// const OPPONENT_PRIVATE_KEY = "2e37d0b92d834960cb8e31ac3b86c947d858f08692e34d944168e3666a50e08d";
// const alchemyProvider = new ethers.providers.AlchemyProvider("goerli", API_KEY);
// const signer = new ethers.Wallet(OPPONENT_PRIVATE_KEY, alchemyProvider);

async function main() {
  const contractAddress = process.env.CONTRACT_ADDRESS || ''

  const [_, p2] = await ethers.getSigners();
  const stake = process.env.GAME_STAKE_ETH || ''
  const p2Nonce = parseInt(process.env.P2_NONCE || '');
  
  const bet = ethers.utils.parseEther(stake);
  const gameContract = new ethers.Contract(contractAddress, contract.abi, p2);
  await gameContract.joinGame(p2Nonce, {value: bet});
}

main();