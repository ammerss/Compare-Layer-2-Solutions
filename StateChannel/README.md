# State Channels 

## Testing : when Player 2 wins for Go
```
npx hardhat test test/go_win.ts
```
## Testing : when Player 2 wins for Tic-Tac-Toe
```
npx hardhat test test/win.ts
```
## Testing on Test nets for Go
Run a complete game. change the network to "goerli" or "arbitrum_goerli"
```shell
npx hardhat run scripts/GoStateChannels.ts --network mumbai
```
## Testing on Test nets for Tic-Tac-Toe
Run a complete game. change the network to "goerli" or "arbitrum_goerli"
```shell
npx hardhat run scripts/StateChannels.ts --network mumbai
```



