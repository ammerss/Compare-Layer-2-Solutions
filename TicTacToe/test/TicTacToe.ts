const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TicTacToe contract", function() {
    async function deployTicTacToeFixture() {
        const turnLength = 10;
        const p1Nonce = 101;
        const p2Nonce = 42;
        const firstMover = (p1Nonce ^ p2Nonce) & 0x01; // first mover will be p2 (bit is 1)
        const p1Commitment = ethers.utils.solidityKeccak256(["uint"], [p1Nonce]);
        const bet = 100;

        const TicTacToe = await ethers.getContractFactory("TicTacToe");
        const [p1, p2, p3] = await ethers.getSigners();
        const bitToPlayer = {0: p1, 1: p2}; // currentPlayer bit -> player address
        const bitToSqVal = {0: 1, 1: 2}; // currentPlayer bit -> sq val

        const game = await TicTacToe.deploy(p2.address, turnLength, p1Commitment, { value: bet });

        await game.deployed();

        return { game, p1, p2, p3, turnLength, bet, p1Nonce, p2Nonce, firstMover, bitToSqVal, bitToPlayer};
    }

    it("joinGame: only p2 can join if stake matched", async function() {
        const { game, p2, p3, bet, p2Nonce } = await loadFixture(deployTicTacToeFixture);

        await expect(game.connect(p3).joinGame(p2Nonce, {value: bet })).to.be.reverted;
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet - 1 })).to.be.reverted;
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
    })

    it("startGame: p1Nonce must match p1Commitment", async function() {
        const { game, p1, p2, bet, p1Nonce, p2Nonce, firstMover } = await loadFixture(deployTicTacToeFixture);
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;

        await expect(game.connect(p1).startGame(102)).to.be.reverted;
        await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;
        expect(await game.currentPlayer()).to.equal(firstMover);
    })

    // we will use this test to test everything relating to playMove
    // just play squares in order
    it ("playMove: firstMover wins", async function() {
        const { game, p1, p2, bet, p1Nonce, p2Nonce, bitToSqVal, firstMover, bitToPlayer } = await loadFixture(deployTicTacToeFixture);
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
        await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;

        let currentPlayer = firstMover;

        // since we're playing squares in-order, first mover wins on move 7 (but 0-indexed)
        for (let i = 0; i < 7; i++) {
            // wrong player can't make move
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(i)).to.be.reverted;

            // right player can make move, board tile saved correctly
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(i)).not.to.be.reverted;
            const sq = await game.board(i);
            expect(await game.board(i)).to.equal(bitToSqVal[currentPlayer]);

            currentPlayer ^= 0x1;

            // next player cannot re-play same square, including after game concluded (7th iteration)
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(i)).to.be.reverted;
        }

        // calling closeGame releases funds to winner
        await expect(game.connect(bitToPlayer[firstMover]).closeGame()).to.changeEtherBalances([bitToPlayer[firstMover].address], [bet*2]);
    })
})