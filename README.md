# Tic-Tac-Toe and Go
We have implemented the game of Tic-Tac-Toe and Go in Solidity and Cairo. They have been tested on testnets such as Goerli, Arbitrum Testnet, Polygon Mumbai and Starknet Testnet.

# Testing
We have made simulations of the whole game where every move is written on to the chain. 
We have also made a simulation version using state channels. In the State channels scripts, none of the player's moves are written to the chain. Only the start and end of the game is submitted to the network because one of the players can submit their proof that they won the game. 

#### Note
Go was implemented in a simplified version where none of the special rules(preventing illegal moves, black plays first etc) are not implemented. 




