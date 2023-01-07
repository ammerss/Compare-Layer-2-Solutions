# TicTacToe Contract (Hardhat)

# Installation
(I think)
```shell
npm install
```

# Contracts

TicTacToe.sol

# Tests

TicTacToe.ts (only tested up to making 1 move)

```shell
npx hardhat test
REPORT_GAS=true npx hardhat test
```

# Scripts

All the scripts below have been designed to be compatible on all networks (L1, L2), you just need to specify the network you're using, which should be defined in `hardhat.config.ts`:

```shell
npx hardhat run scripts/0_deploy.ts --network goerli
```

or

```shell
npx hardhat run scripts/0_deploy.ts --network arbitrum_goerli
```

## Deploy
You will need to change the CONTRACT_ADDRESS env var for subsequent interactions. The contract address will be returned (printed) after running this deploy script.

You can also change P2_PUBKEY to pick another opponent, as well as GAME_STAKE_ETH, GAME_TURN_LENGTH, and P1_NONCE to change the parameters of the game.

```shell
npx hardhat run scripts/0_deploy.ts --network <network>
```

## Debug
The debug script prints out the contract's state, and can be called at any time to see the current game state, say after you play a move and want to check that it got recorded.

```shell
npx hardhat run scripts/0_debug.ts --network <network>
```

## Join the game as P2
You can change P2_NONCE if you wish.

```shell
npx hardhat run scripts/1_join_game.ts --network <network>
```

## Start game as P1
```shell
npx hardhat run scripts/2_start_game.ts --network <network>
```

## Play moves
You will repeat this script every time you want to make a move, changing the cmd line env var PLAYER to the current player (1 / 2) and the SQUARE you wish to play (0-8)

```shell
PLAYER=1 SQUARE=4 npx hardhat run scripts/3_play_move.ts --network <network>
```

## Conclude the game
When the game ends, call this script to transfer the winnings to the winner (or split if tie).
The player env var is just the script-calling player, the winnigs will still go to the correct player(s).

```
PLAYER=1 npx hardhat run scripts/4_close_game.ts --network <network>
```