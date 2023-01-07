import pytest
import random
from starkware.starknet.testing.starknet import Starknet
from timeit import default_timer as timer
from enum import Enum

class States(Enum): 
    P1_TURN = 0
    P2_TURN = 1
    GAME_OVER = 2
    GAME_NOT_STARTED = 3

GRIDX, GRIDY = 9, 9
CONTRACT = "../Go.cairo"

@pytest.mark.asyncio
async def test_game_initialization():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(CONTRACT)

    # start game with P1 and check game state
    await contract.start_game(GRIDX, GRIDY).execute()
    (game_state) = await contract.get_game_state().call()
    assert game_state.result.state == States.GAME_NOT_STARTED.value
    
    # join game as P2 and check game state
    await contract.join().execute()
    (game_state) = await contract.get_game_state().call()
    assert game_state.result.state == States.P1_TURN.value

@pytest.mark.asyncio
async def test_valid_move():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(CONTRACT)
    
    # start game with P1 and P2 and check game state
    await contract.start_game(GRIDX, GRIDY).execute()
    await contract.join().execute()

    # make random move as player 1
    rx, ry = random.randint(0, GRIDX-1), random.randint(0, GRIDY-1)
    pmove = await contract.player_move(rx, ry, States.P1_TURN.value).execute()
    board = await contract.get_board_at(rx, ry).call()

    # check for success and update
    assert (pmove.result.valid == True)
    assert (board.result.value == 0)

@pytest.mark.asyncio
async def test_capture():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(CONTRACT)
    
    # start game with P1 and P2 and check game state
    await contract.start_game(GRIDX, GRIDY).execute()
    await contract.join().execute()

    # make random move as player 1
    moves = [(0, 1), (1, 1), (1, 0), (5, 5), (1, 2), (4, 4), (2, 1), (7, 7)]
    expected_board = [[2 for _ in range(GRIDY)] for _ in range(GRIDX)]
    
    # execute moves
    for i in range(len(moves)): 
        nx, ny = moves[i]
        expected_board[nx][ny] = i % 2
        pmove = await contract.player_move(nx, ny, i % 2).execute()
        assert (pmove.result.valid == True)
    # mark captured cell as Empty
    expected_board[1][1] = 2

    # compare expected grid and actual grid
    for i in range(GRIDX): 
        for j in range(GRIDY): 
            curr_val = await contract.get_board_at(i, j).call()
            print(i, j, ": ", curr_val.result.value)
            assert curr_val.result.value == expected_board[i][j]