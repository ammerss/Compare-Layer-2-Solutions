// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GoStateChannel {
    enum GameState{ OPEN, ONGOING, CLOSED}
    enum GameOutcome { TIE, P1WIN, P2WIN } // TODO: Add P1WINBYDEFAULT, P2WINBYDEFAULT

    GameState public gameState;
    GameOutcome public gameOutcome;


    address[2] public players;
    uint32 public turnLength;

    bytes32 public p1Commitment;
    uint public p2Nonce;
    
    uint public boardsize = 9;
    uint[19][19] public board; 

    uint8 public currentPlayerBit;
    uint public currentPlayer;
    uint public firstPlayer;
    uint256 public turnDeadline;
    
    uint endgame = 0;
    //mapping(uint => uint) 
    uint[2] public capture_scores;


    uint32 public challengeLength; // TODO:
    // uint256 public challengeDeadline;
    // GameOutcome public proposedOutcome;

    constructor(address _opponent, uint32 _challengeLength, bytes32 _p1Commitment, uint _boardsize) payable {
        players[0] = msg.sender;
        players[1] = _opponent;
        p1Commitment = _p1Commitment;

        challengeLength = _challengeLength;
        gameState = GameState.OPEN;
        boardsize = _boardsize;
    }

    function joinGame(uint8 _p2Nonce) public payable {
        require (gameState == GameState.OPEN, "game is not open");
        require(msg.sender == players[1], "only P2 can join the game");
        require(msg.value >= (address(this).balance / 2) + (address(this).balance % 2), "you must match the game stake");
        p2Nonce = _p2Nonce;
    }

    function startGame(uint p1Nonce) public {
        require (turnDeadline == 0, "game has already started");
        require(msg.sender == players[0], "only P1 can start the game");
        require(keccak256(abi.encode(p1Nonce)) == p1Commitment);

        currentPlayer = (p1Nonce ^ p2Nonce) & 0x01;
        currentPlayerBit = uint8((p1Nonce ^ p2Nonce) & 0x01);
        firstPlayer = currentPlayer;
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
    function challenge(GameOutcome _proposedOutcome, bytes memory encodedPrevState, bytes memory signedPrevState, bytes memory captureScores ) public {
        address currPlayer = players[0];
        address otherPlayer = players[1];
        uint currPlayerVal = 1;
        if (_proposedOutcome == GameOutcome.P2WIN) {
            currPlayer = players[1];
            otherPlayer = players[0];
            currPlayerVal = 2;
        }

        // prev state must be signed by opponent
        address prevSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(encodedPrevState)), signedPrevState);
        require(prevSigner == otherPlayer, "prevState invalid sig");
        // we can now just use it as the base state
        board = abi.decode(encodedPrevState, (uint[19][19]));
        capture_scores = abi.decode(captureScores, (uint[2]));


        //scoring system
        //find empty squares on board and fill them in
        fillBoard();
        //count all the stones
        //console.log(checkGameOver(),capture_scores[0],capture_scores[]);
        //console.log(_proposedOutcome);


        require(_proposedOutcome == checkGameOver() ,"not the desired outcome");

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

    function fillBoard() public{
        //fill in the board with black, white, or neutral.
        int[4] memory dx = [int(-1),0,1,0];  // 0:up, 1:right, 2:down, 3:left
        int[4] memory dy = [int(0),1,0,-1];
        for (uint i=0;i<boardsize;i++){
            for (uint j=0;j<boardsize;j++){
                uint black = 0;
                uint white = 0;
                if(board[i][j]==0){
                    for (uint n = 0; n< 4; n ++){
                        int nx = int(i) + dx[n];
                        int ny = int(j) + dy[n];
                        // if adjacent square is empty keep going
                        while(boundaryCheck(nx, ny) == 1 && board[uint(nx)][uint(ny)] == 0){
                            nx = nx + dx[n];
                            ny = ny + dy[n];
                        }
                        if (boundaryCheck(nx, ny) == 0) continue;
                        if (board[uint(nx)][uint(ny)] == 1) black ++;
                        else if(board[uint(nx)][uint(ny)] == 2) white ++;
                    }
                }
                else{
                    if(board[i][j]==1)black++;
                    else if(board[i][j]==0)white++;
                }
                if(black==2 && white ==2) 
                    board[i][j] = 3;
                else if (black > 2)
                    board[i][j] = 1;
                else if(white> 2)
                    board[i][j] = 2;
                else 
                    board[i][j] = 3;
            }
        }
    }

    function checkGameOver() public view returns (GameOutcome) {
        // iterate the board and count black and white stones
        uint p1score = 0;
        uint p2score = 0;
        for (uint i=0;i<boardsize;i++){
            for (uint j=0;j<boardsize;j++){
                if (board[i][j] == 1) {
                    p1score++;
                }
                else if (board[i][j] == 2) {
                    p2score++;
                }
            }
        }

        p1score += capture_scores[0];
        p2score += capture_scores[1];


        if (p1score > p2score) {
            return GameOutcome.P1WIN;
        } 
        else if (p2score > p1score) {
            return GameOutcome.P2WIN;
        }
        return GameOutcome.TIE;
    }
  

    function boundaryCheck(int squareToPlayX , int squareToPlayY) public view returns (uint check) {
        if (squareToPlayX < 0 || squareToPlayX >= int(boardsize)) return 0;
        if (squareToPlayY < 0 || squareToPlayY >= int(boardsize)) return 0;
        return 1;      
    }    

}