// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "hardhat/console.sol";
import "./queue.sol";

//go rules
//https://www.britgo.org/files/rules/GoQuickRef.pdf 

//go game in c++
//https://github.com/marthaurion/gobang 

//Go - How does one count territory in these two scenarios? (9x9) 
//https://boardgames.stackexchange.com/questions/20375/go-how-does-one-count-territory-in-these-two-scenarios-9x9 

//How to count territory of Go game in general C++ code? 
//https://stackoverflow.com/questions/38288308/how-to-count-territory-of-go-game-in-general-c-code

contract Go {
    using queue for queue.Queue;
    queue.Queue  qx;
    queue.Queue  qy;
    queue.Queue  toRemovex;
    queue.Queue  toRemovey;

    address[2] public players;
    uint32 public turnLength;

    bytes32 public p1Commitment;
    uint public p2Nonce;
    
    uint public boardsize = 9;
    uint[19][19] public board; 

    uint public currentPlayer;
    uint256 public turnDeadline;
    
    uint endgame = 0;
    mapping(uint => uint) public capture_scores;

    enum GameState{ OPEN, ONGOING, CLOSED}
    enum GameOutcome { TIE, P1WIN, P2WIN }

    GameState public gameState;
    GameOutcome public gameOutcome;


    // p1 inits the game
    constructor(address _opponent, uint32 _turnLength, bytes32 _p1Commitment, uint _boardsize) payable {
        players[0] = msg.sender;
        players[1] = _opponent;
        turnLength = _turnLength;
        p1Commitment = _p1Commitment;
        boardsize = _boardsize;
        gameState = GameState.OPEN;
    }

    // p2 joins
    function joinGame(uint8 _p2Nonce) public payable {
        require (gameState == GameState.OPEN, "game is not open");
        require(msg.sender == players[1], "only P2 can join the game");
        require(msg.value >= (address(this).balance / 2) + (address(this).balance % 2), "you must match the game stake");
        p2Nonce = _p2Nonce;
    }

    // p1 officially starts the game, decides who plays first
    function startGame(uint p1Nonce) public {
        require (gameState == GameState.OPEN, "game is not open");
        require(msg.sender == players[0], "only P1 can start the game");
        require(keccak256(abi.encode(p1Nonce)) == p1Commitment);
        
        currentPlayer = (p1Nonce ^ p2Nonce) & 0x01;
        turnDeadline = block.number + turnLength;
        gameState = GameState.ONGOING;
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

    function passMove() public{
        require(turnDeadline > 0, "game has not started");
        require(msg.sender == players[currentPlayer], "it is not your turn");
        endgame++;

        // game is over if both the players pass consecutively
        if (endgame == 2){
            // find empty squares on board and fill them in
            fillBoard();
            // count all the stones
            gameOutcome = checkGameOver();
            gameState = GameState.CLOSED;
        }

        currentPlayer ^= 0x1;
        turnDeadline = block.number + turnLength;
    }

    // closeGame is called after the game has concluded, to transfer funds to winner(s)
    function closeGame() public {
        require (gameState == GameState.CLOSED, "game is not closed");

        if (gameOutcome == GameOutcome.TIE) {
            uint half = address(this).balance / 2;
            payable(players[0]).transfer(half);
            payable(players[1]).transfer(half);
        } else if (gameOutcome == GameOutcome.P1WIN) {
            payable(players[0]).transfer(address(this).balance);
        } else if (gameOutcome == GameOutcome.P2WIN) {
            payable(players[1]).transfer(address(this).balance);
        }

        selfdestruct(payable(msg.sender)); // there should be nothing left at this point
    }

    
    function playMove(uint squareToPlayX , uint squareToPlayY) public {
        require (gameState == GameState.ONGOING, "game is not ongoing");
        require (msg.sender == players[currentPlayer], "it is not your turn");
        require (boundaryCheck(int(squareToPlayX),int(squareToPlayY)) == 1, "Out of bound move");
        require (board[squareToPlayX][squareToPlayY] == 0, "square has been played");

        endgame = 0;
        board[squareToPlayX][squareToPlayY] = currentPlayer + 1;
        
        //check to see if the move captures any pieces
        //remove the captured pieces
        checkCaptures(squareToPlayX , squareToPlayY);

        currentPlayer ^= 0x1;
        turnDeadline = block.number + turnLength;
    }


    function defaultGame() public {
        require (turnDeadline > 0, "game has not started");
        require (block.number > turnDeadline, "turn deadline not exceeded");
        require (msg.sender == (players[currentPlayer ^ 0x1]), "the game is not yours to default");
        selfdestruct(payable(msg.sender));
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

                if (black == 0){
                    board[i][j]=2;
                }
                else if (white == 0){
                    board[i][j] = 1;
                }
                else 
                    board[i][j]=3;
            }
        }
    }


    function checkCaptures(uint squareX , uint squareY) public {
        //keep track of redundant visits
        uint[19][19] memory visited;

        //checks whether current player made suicide move
        findCaptures(squareX, squareY, 0 , visited);

        uint oppositePlayer;
        if(currentPlayer ==1) oppositePlayer = 0;
        else oppositePlayer = 1;

        //checks whether current player captured any stones
        if (boundaryCheck(int(squareX) + 1, int(squareY))== 1) findCaptures(squareX+1, squareY, 1 , visited);
        if (boundaryCheck(int(squareX), int(squareY) + 1)== 1) findCaptures(squareX, squareY+1, 1 , visited);
        if (boundaryCheck(int(squareX) - 1, int(squareY))== 1) findCaptures(squareX-1, squareY, 1 , visited);
        if (boundaryCheck(int(squareX), int(squareY) - 1)== 1) findCaptures(squareX, squareY-1, 1 , visited);
    }

    function findCaptures(uint squareX , uint squareY, uint flag, uint[19][19] memory visited) public returns (uint){
        //bfs to find the whole connected group
        int[4] memory dx = [int(-1),0,1,0];  // 0:up, 1:right, 2:down, 3:left
        int[4] memory dy = [int(0),1,0,-1];
        uint cnt;
        while(!toRemovex.empty()){ // in case it's not empty
            toRemovex.pop();
            toRemovey.pop();
        }

        if(calcLiberties(int(squareX), int(squareY)) > 0) return 0; //only bfs if no liberties
        //if(flag==0 && board[squareX][squareY] == (currentPlayer ^ 0x1) + 1)return 0;
        if(flag==1 && board[squareX][squareY] ==  currentPlayer + 1)return 0; 

        if(visited[squareX][squareY] == 0){
            //if this was visited we will not bfs over and just return 0
            qx.push(squareX);
            qy.push(squareY);
            visited[squareX][squareY]=1;

            toRemovex.push(squareX);
            toRemovey.push(squareY);
            cnt++;
        }
        
        while(!qx.empty()){
            uint x;
            uint y;
            x = qx.pop();
            y = qy.pop();

            for (uint i=0;i<4;i++){
                int nx = int(x) + dx[i];
                int ny = int(y) + dy[i];


                if(boundaryCheck(nx, ny) == 0) continue;
                    
                if (flag ==0){
                    if(visited[uint(nx)][uint(ny)]==0 && calcLiberties(nx, ny) == 0 && board[uint(nx)][uint(ny)] == currentPlayer + 1){
                        visited[uint(nx)][uint(ny)]=1;
                        qx.push(uint(nx));
                        qy.push(uint(ny));
                        toRemovex.push(uint(nx));
                        toRemovey.push(uint(ny));
                        cnt ++;
                    }
                    // if any liberty exist this is not a captured group
                    else if(calcLiberties(nx, ny) > 0 && board[uint(nx)][uint(ny)] == currentPlayer + 1) return 0;
                }
                else if (flag ==1){
                    
                    if(visited[uint(nx)][uint(ny)]==0 && calcLiberties(nx, ny) == 0 && board[uint(nx)][uint(ny)] == (currentPlayer ^ 0x1) + 1){
                        visited[uint(nx)][uint(ny)]=1;
                        qx.push(uint(nx));
                        qy.push(uint(ny));
                        toRemovex.push(uint(nx));
                        toRemovey.push(uint(ny));
                        cnt ++;
                    }
                    // if any liberty exist this is not a captured group
                    else if(calcLiberties(nx, ny) > 0 && board[uint(nx)][uint(ny)] == (currentPlayer ^ 0x1) + 1) return 0;
                
                }
            }
        }

        
        if(flag == 0){ //if current player was captured
            capture_scores[currentPlayer ^ 0x1] += cnt; 
        }
        else{
            capture_scores[currentPlayer] += cnt; 
        }

        //remove the captured pieces from board
        while(!toRemovex.empty()){
            uint x;
            uint y;
            x = toRemovex.pop();
            y = toRemovey.pop();
            board[x][y] = 0;
        }

        return cnt;
    }


    function calcLiberties(int squareX , int squareY) public view returns (uint) {
        //Find and return the liberties of the point.
        int[4] memory x = [int(-1),0,1,0];  // 0:up, 1:right, 2:down, 3:left
        int[4] memory y = [int(0),1,0,-1];
        uint liberties = 0;
        for (uint i = 0; i< 4; i ++){
            int nx = squareX + x[i];
            int ny = squareY + y[i];
            //if boundary is valid inside board then check if it's empty
            if(boundaryCheck(nx, ny) == 1 && board[uint(nx)][uint(ny)] == 0) liberties++;
        }
        return liberties;
    }
    

}




