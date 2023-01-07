const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
  
describe("Go", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployGoFunction() {
        const turnLength = 10;
        const p1Nonce = 101;
        const p2Nonce = 42;
        const firstMover = (p1Nonce ^ p2Nonce) & 0x01; // first mover will be p2 (bit is 1)
        const p1Commitment = ethers.utils.solidityKeccak256(["uint"], [p1Nonce]);
        const bet = 100;
        const boardsize = 9; //choose board size here
        

        const [p1, p2, p3] = await ethers.getSigners();

        const bitToPlayer = {0: p1, 1: p2}; // currentPlayer bit -> player address
        const bitToSqVal = {0: 1, 1: 2}; // currentPlayer bit -> sq val

        
        const Q = await ethers.getContractFactory("queue");
        const Qlib = await Q.deploy();
        await Qlib.deployed();

        const Go = await ethers.getContractFactory("Go", {
            libraries: {
                queue: Qlib.address,
            },
        });

        const game = await Go.deploy(p2.address, turnLength, p1Commitment, boardsize, { value: bet });

        return { game, p1, p2, p3, turnLength, bet, p1Nonce, p2Nonce, firstMover, bitToSqVal, bitToPlayer};
        
    }
  
    describe("Start", function () {
      it("joinGame: only p2 can join if stake matched", async function () {
        let now = new Date();
        const start = now.getSeconds() 
        console.log(start);
        const { game, p2, p3, bet, p2Nonce } = await loadFixture(deployGoFunction);
        await expect(game.connect(p3).joinGame(p2Nonce, {value: bet })).to.be.reverted;
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet - 1 })).to.be.reverted;
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
        const end = now.getSeconds() 
        console.log(end);
      });

      it("startGame: p1Nonce must match p1Commitment", async function() {
        const { game, p1, p2, bet, p1Nonce, p2Nonce, firstMover } = await loadFixture(deployGoFunction);
        await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
        await expect(game.connect(p1).startGame(102)).to.be.reverted;
        await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;
        expect(await game.currentPlayer()).to.equal(firstMover);

      });

    });
    describe("Play Game", function () {
        it("players take turn", async function () {
            const { game, p1, p2, bet, p1Nonce, p2Nonce, bitToSqVal, firstMover, bitToPlayer } = await loadFixture(deployGoFunction);
            await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
            await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;

            let currentPlayer = firstMover;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(0,2)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(1,4)).to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(1,5)).not.to.be.reverted;
          });
          
        it("player 1 captures player 2 - 1", async function () {
            const { game, p1, p2, bet, p1Nonce, p2Nonce, bitToSqVal, firstMover, bitToPlayer } = await loadFixture(deployGoFunction);
            await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
            await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;

            let currentPlayer = firstMover;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(0,1)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(8,8)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(1,0)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(8,7)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(1,2)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(1,1)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(2,1)).not.to.be.reverted; // this captures stone at (1,1)

            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(1,1)).not.to.be.reverted;

            //0 B 0
            //B W B
            //0 B 0
        });
        it("player 1 captures player 2 - 3", async function () {
            const { game, p1, p2, bet, p1Nonce, p2Nonce, bitToSqVal, firstMover, bitToPlayer } = await loadFixture(deployGoFunction);
            await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
            await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;

            let currentPlayer = firstMover;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(0,2)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(0,0)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(1,1)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(0,1)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(2,0)).not.to.be.reverted;
            await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).playMove(1,0)).not.to.be.reverted; // this is suicide move

            await expect(game.connect(bitToPlayer[currentPlayer]).playMove(1,0)).not.to.be.reverted; 

            //W W B
            //W B 0
            //B 0 0
          });

    });

    describe("End Game", function () {
        it("game is over after 2 pass", async function () {
            const { game, p1, p2, bet, p1Nonce, p2Nonce, bitToSqVal, firstMover, bitToPlayer } = await loadFixture(deployGoFunction);
            await expect(game.connect(p2).joinGame(p2Nonce, {value: bet })).not.to.be.reverted;
            await expect(game.connect(p1).startGame(p1Nonce)).not.to.be.reverted;

            let currentPlayer = firstMover;
            await expect(game.connect(bitToPlayer[currentPlayer]).passMove()).not.to.be.reverted;
            //await expect(game.connect(bitToPlayer[currentPlayer ^ 0x1]).passMove()).not.to.be.reverted;
            // await expect(await game.connect(bitToPlayer[currentPlayer ^ 0x1]).passMove()).to.changeEtherBalance(p1, bet);

          });

    });
  });
  