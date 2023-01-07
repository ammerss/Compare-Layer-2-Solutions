// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract StateChannel {
    enum GameState{ OPEN, ONGOING, CLOSED}
    enum GameOutcome { TIE, P1WIN, P2WIN } // TODO: Add P1WINBYDEFAULT, P2WINBYDEFAULT

    GameState public gameState;
    GameOutcome public gameOutcome;

    address[2] public players;

    bytes32 public p1Commitment;
    uint8 public p2Nonce;

    uint8[9] public board;
    uint8 public currentPlayerBit; // 0-indexed

    uint32 public challengeLength; // TODO:
    // uint256 public challengeDeadline;
    // GameOutcome public proposedOutcome;

    constructor(address _opponent, uint32 _challengeLength, bytes32 _p1Commitment) payable {
        players[0] = msg.sender;
        players[1] = _opponent;
        p1Commitment = _p1Commitment;

        challengeLength = _challengeLength;
        gameState = GameState.OPEN;
    }

    function joinGame(uint8 _p2Nonce) public payable {
        require (gameState == GameState.OPEN, "game is not open");
        require(msg.sender == players[1], "only P2 can join the game");
        require(msg.value >= (address(this).balance / 2) + (address(this).balance % 2), "you must match the game stake");
        p2Nonce = _p2Nonce;
    }

    function startGame(uint8 p1Nonce) public {
        require (gameState == GameState.OPEN, "game is not open");
        require(msg.sender == players[0], "only P1 can start the game");
        require(keccak256(abi.encode(p1Nonce)) == p1Commitment);
        
        currentPlayerBit = (p1Nonce ^ p2Nonce) & 0x01;
        gameState = GameState.ONGOING;
    }

    // function isValidTransition(bytes _old, bytes _new) public pure returns (bool) {
    //     bytes memory x = abi.encode(board, currentPlayer);
    //     console.logBytes(x);
    //     (uint8[9] memory y, uint8 z) = abi.decode(x, (uint8[9], uint8));
    //     for (uint i = 0; i < 3; i++) {
    //         console.log(string.concat(Strings.toString(y[i*3]), Strings.toString(y[i*3+1]), Strings.toString(y[i*3+2])));
    //     }
    //     console.log(z);
    // }

    // Protocol Assumptions:
    // 1. Signing player made the last move.

    // Scenarios and required proof:
    // 
    // 1. I win
    // - previous state signed by opponent (me using this means we both agree it is a valid previous state)
    // - indexes of 2 of my previous tiles, + index of my winning move, played from the previous state.
    // 
    // 2. TODO: We tie (;they provide winning 3 or valid move)
    // 
    // 3. TODO: They defaulted (;they can respond before timeout)
    function challenge(GameOutcome _proposedOutcome, bytes memory encodedPrevState, bytes memory signedPrevState, bytes memory encodedWinningMoves) public {
        address currPlayer = players[0];
        address otherPlayer = players[1];
        uint8 currPlayerVal = 1;
        if (_proposedOutcome == GameOutcome.P2WIN) {
            currPlayer = players[1];
            otherPlayer = players[0];
            currPlayerVal = 2;
        }

        // prev state must be signed by opponent
        address prevSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(encodedPrevState)), signedPrevState);
        require(prevSigner == otherPlayer, "prevState invalid sig");
        // we can now just use it as the base state
        (uint8[9] memory prevState) = abi.decode(encodedPrevState, (uint8[9]));

        // winner must provide the boxes leading up to their winning move, played from the previous state
        (uint8[3] memory winningMoves) = abi.decode(encodedWinningMoves, (uint8[3]));
        require(prevState[winningMoves[0]] == currPlayerVal, "first tile does not belong to you");
        require(prevState[winningMoves[1]] == currPlayerVal, "second tile does not belong to you");
        require(prevState[winningMoves[2]] == 0, "third tile is not empty");

        // set the game outcome so that winner can closeGame().
        gameOutcome = _proposedOutcome;
        gameState = GameState.CLOSED;
    }

    // TODO: Other player will need to respond with, in case of fraud:
    // (a) a move they made after (higher nonce / more pieces, if it's Bob's move, does not require Alice's signature), new challenge period for Alice to submit newer move
    // (b) the 
    function respond(GameState _gameState, bytes32 myMove) public {
    }

    // closeGame is called after the game has concluded, to transfer funds to winner(s)
    function closeGame() public {
        require (gameState == GameState.CLOSED, "game is not closed");

        if (gameOutcome == GameOutcome.TIE) {
            uint half = address(this).balance;
            payable(players[0]).transfer(half);
            payable(players[1]).transfer(half);
        } else if (gameOutcome == GameOutcome.P1WIN) {
            payable(players[0]).transfer(address(this).balance);
        } else if (gameOutcome == GameOutcome.P2WIN) {
            payable(players[1]).transfer(address(this).balance);
        }

        selfdestruct(payable(msg.sender)); // there should be nothing left at this point
    }
}