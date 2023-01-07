import pytest
from starkware.starknet.testing.starknet import Starknet
from timeit import default_timer as timer
from enum import Enum

class States(Enum): 
    GAME_NOT_STARTED = 0
    P1_TURN = 1
    P2_TURN = 2
    P1_WIN = 3 
    P2_WIN = 4 
    TIE = 5    

@pytest.mark.asyncio
async def test_game_initialization():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("TicTacToe.cairo")

    # game initialization
    await contract.start_game().execute() # first user joined
    await contract.join().execute() # second user joined

    # get game state
    (game_state) = await contract.get_game_state().call()
    assert game_state.result.value == States.P1_TURN.value

# @pytest.mark.asyncio
# async def test_invalid_user_move():
#     print()

#     starknet = await Starknet.empty()
#     contract = await starknet.deploy("TicTacToe.cairo")

#     # game initialization
#     await contract.start_game().execute() # first user joined
#     await contract.join().execute() # second user joined

#     # make move

@pytest.mark.asyncio
async def test_valid_user_move():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("TicTacToe.cairo")

    # game initialization
    await contract.start_game().execute() # first user joined
    await contract.join().execute() # second user joined

    # make P1 move and test state + board
    await contract.user_move(1, 0).execute()
    (game_state) = await contract.get_game_state().call()
    assert game_state.result.value == States.P2_TURN.value

    (board) = await contract.view_board().call()
    assert board.result.b0 == 1

    # make P2 move and test state + board
    await contract.user_move(2, 7).execute()
    (game_state) = await contract.get_game_state().call()
    assert game_state.result.value == States.P1_TURN.value

    (board) = await contract.view_board().call()
    assert board.result.b7 == 2

@pytest.mark.asyncio
async def test_row_win():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("TicTacToe.cairo")

    # game initialization
    await contract.start_game().execute() # first user joined
    await contract.join().execute() # second user joined

    moves = [(1, 6), (2, 0), (1, 7), (2, 1), (1, 8)]
    # make P1 move and test state + board
    for p, m in moves: 
        await contract.user_move(p, m).execute()

    (board) = await contract.view_board().call()
    print(board.result.b6, board.result.b7, board.result.b8)

    (game_state) = await contract.get_game_state().call()
    assert game_state.result.value == States.P1_WIN.value

@pytest.mark.asyncio
async def test_col_win():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("TicTacToe.cairo")

    # game initialization
    await contract.start_game().execute() # first user joined
    await contract.join().execute() # second user joined

    moves = [(1, 2), (2, 0), (1, 4), (2, 3), (1, 5), (2, 6)]
    # make P1 move and test state + board
    for p, m in moves: 
        await contract.player_move(p, m).execute()
    
    (game_state) = await contract.get_game_state().call()
    assert game_state.result.value == States.P2_WIN.value

@pytest.mark.asyncio
async def test_diag_win():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("TicTacToe.cairo")

    # game initialization
    await contract.start_game().execute() # first user joined
    await contract.join().execute() # second user joined

    moves = [(1, 0), (2, 1), (1, 4), (2, 3), (1, 2), (2, 5), (1, 8)]
    # make P1 move and test state + board
    for p, m in moves: 
        await contract.user_move(p, m).execute()
    
    (game_state) = await contract.get_game_state().call()
    assert game_state.result.value == States.P1_WIN.value