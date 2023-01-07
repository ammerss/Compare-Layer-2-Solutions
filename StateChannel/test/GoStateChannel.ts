const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GoStateChannel contract", function() {
    async function deployGoStateChannelFixture() {
        const turnLength = 10;
        const p1Nonce = 101;
        const p2Nonce = 42;
        const firstMover = (p1Nonce ^ p2Nonce) & 0x01; // first mover will be p2 (bit is 1)
        const p1Commitment = ethers.utils.solidityKeccak256(["uint"], [p1Nonce]);
        const bet = 100;

        const StateChannel = await ethers.getContractFactory("GoStateChannel");
        const [p1, p2, p3] = await ethers.getSigners();
        const bitToPlayer = {0: p1, 1: p2}; // currentPlayer bit -> player address
        const bitToSqVal = {0: 1, 1: 2}; // currentPlayer bit -> sq val
        const boardsize = 9;

        const game = await StateChannel.deploy(p2.address, turnLength, p1Commitment, boardsize, { value: bet });

        return { game, p1, p2, p3, turnLength, bet, p1Nonce, p2Nonce, firstMover, bitToSqVal, bitToPlayer};
    }

    it("joinGame: only p2 can join if stake matched", async function() {
        const { game, p2, p3, bet, p2Nonce } = await loadFixture(deployGoStateChannelFixture);

        await expect(game.connect(p3).joinGame(p2Nonce, {value: bet })).to.be.reverted;
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet - 1 })).to.be.reverted;
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
    })

    it("startGame: p1Nonce must match p1Commitment", async function() {
        const { game, p1, p2, bet, p1Nonce, p2Nonce, firstMover } = await loadFixture(deployGoStateChannelFixture);
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;

        await expect(game.connect(p1).startGame(102)).to.be.reverted;
        await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;
        expect(await game.currentPlayer()).to.equal(firstMover);
    })

    it ("challenge: firstMover wins", async function() {
        const { game, p1, p2, bet, p1Nonce, p2Nonce, bitToSqVal, firstMover, bitToPlayer } = await loadFixture(deployGoStateChannelFixture);
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
        await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;

        const currentPlayerBit = firstMover;
        const otherPlayerBit = currentPlayerBit ^ 0x1;
        const currentPlayer = bitToPlayer[currentPlayerBit];
        const otherPlayer = bitToPlayer[otherPlayerBit];
        const currentPlayerVal = bitToSqVal[currentPlayerBit];
        const otherPlayerVal = bitToSqVal[otherPlayerBit];

        // setup the board so that currentPlayer can win in the next move
        /*const prevState = [  
            currentPlayerVal, otherPlayerVal, currentPlayerVal,
            otherPlayerVal, currentPlayerVal, otherPlayerVal,
            0, 0, 0
        ];*/

        const prevState = [  //19*19
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    ]
        const capture_scores= [0, 10];

        
        const abi = ethers.utils.defaultAbiCoder;
        const winningMoves = [2, 4];
        //const encodedWinningMoves = abi.encode(["uint[2]"], [winningMoves]);

        const encodedCaptureScores = abi.encode(["uint[2]"],[capture_scores]);
        const encodedPrevState = abi.encode(["uint[19][19]"], [prevState]);
        const hashedPrevState : string = ethers.utils.solidityKeccak256(["uint[19][19]"], [prevState]);
        const signedPrevState : string = await otherPlayer.signMessage(ethers.utils.arrayify(hashedPrevState));

        // winner must be able to claim they won successfully
        await expect(game.connect(currentPlayer).challenge(currentPlayerVal, encodedPrevState, signedPrevState, encodedCaptureScores)).not.to.be.reverted;

        // calling closeGame releases funds to winner
        //await expect(game.connect(currentPlayer).closeGame()).to.changeEtherBalances([currentPlayer], [bet*2]);
    })
})