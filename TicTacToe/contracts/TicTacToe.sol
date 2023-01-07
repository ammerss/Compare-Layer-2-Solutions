// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TicTacToe {
    enum GameState{ TIE, P1WIN, P2WIN, ONGOING }
    address[2] public players;
    uint32 public turnLength;

    bytes32 public p1Commitment;
    uint8 public p2Nonce;

    uint8[9] public board;
    uint8 public currentPlayer; // 0-indexed
    uint256 public turnDeadline;

    constructor(address _opponent, uint32 _turnLength, bytes32 _p1Commitment) payable {
        players[0] = msg.sender;
        players[1] = _opponent;
        turnLength = _turnLength;
        p1Commitment = _p1Commitment;
    }

    function joinGame(uint8 _p2Nonce) public payable {
        require(msg.sender == players[1], "you are not the target opponent for this game");
        require(msg.value >= (address(this).balance / 2) + (address(this).balance % 2), "you must match the game stake");
        require (turnDeadline == 0, "game has already started");
        p2Nonce = _p2Nonce;
    }

    function startGame(uint8 p1Nonce) public {
        require (turnDeadline == 0, "game has already started");
        require(keccak256(abi.encode(p1Nonce)) == p1Commitment);
        
        currentPlayer = (p1Nonce ^ p2Nonce) & 0x01;

        turnDeadline = block.number + turnLength;
    }

    function isBoardFull() public view returns (bool) {
        for (uint i = 1; i < 9; i++) {
            if (board[i] == 0) {
                return false;
            }
        }
        return true;
    }

    function checkGameOver() public view returns (GameState) {
        // 0 1 2
        // 3 4 5
        // 6 7 8

        // check if any player has won
        for (uint player = 1; player < 3; player++) {  
            // consecutive in row?
            for (uint i = 0; i < 3; i++) {
                if ((board[i*3] == player) && (board[i*3+1] == player) && (board[i*3+2] == player)) {
                    return GameState(player);
                }
            }
            // consecutive in col?
            for (uint j = 0; j < 3; j++) {
                if ((board[j] == player) && (board[j+3] == player) && (board[j+6] == player)) {
                    return GameState(player);
                }
            }
            // consecutive in diagonals?
            if ((board[0] == player) && (board[4] == player) && (board[8] == player)) {
                return GameState(player);
            } else if ((board[2] == player) && (board[4] == player) && (board[6] == player)) {
                return GameState(player);
            }
        }

        if (isBoardFull()) {
            return GameState.TIE;
        }

        return GameState.ONGOING;
    }

    function playMove(uint8 squareToPlay) public {
        require (turnDeadline > 0, "game has not started");
        require (msg.sender == players[currentPlayer], "it is not your turn");
        require(squareToPlay < 9, "square is out of bounds");
        require (board[squareToPlay] == 0, "square has been played");
        require (checkGameOver() == GameState.ONGOING, "game has concluded");

        board[squareToPlay] = currentPlayer + 1;

        // for (uint i = 0; i < 3; i++) {
        //     console.log(string.concat(Strings.toString(board[i*3]), Strings.toString(board[i*3+1]), Strings.toString(board[i*3+2])));
        // }

        // console.log(string.concat("gameState: ", Strings.toString(uint(checkGameOver()))));

        currentPlayer ^= 0x1;

        turnDeadline = block.number + turnLength;
    }

    // closeGame is called after a player wins the game, to transfer funds to winner
    function closeGame() public {
        GameState gameState = checkGameOver();
        require (gameState != GameState.ONGOING, "game is ongoing");

        if (gameState == GameState.TIE) {
            uint half = address(this).balance / 2;
            payable(players[0]).transfer(half);
            payable(players[1]).transfer(half);
        } else if (gameState == GameState.P1WIN) {
            payable(players[0]).transfer(address(this).balance);
        } else if (gameState == GameState.P2WIN) {
            payable(players[1]).transfer(address(this).balance);
        }

        selfdestruct(payable(msg.sender)); // there should be nothing left at this point
    }

    // defaultGame is called if your opponent exceeds their deadline, to forfeit them
    function defaultGame() public {
        require (turnDeadline > 0, "game has not started");
        require (block.number > turnDeadline, "turn deadline not exceeded");
        require (msg.sender == (players[currentPlayer ^ 0x1]), "the game is not yours to default");
        selfdestruct(payable(msg.sender));
    }


}