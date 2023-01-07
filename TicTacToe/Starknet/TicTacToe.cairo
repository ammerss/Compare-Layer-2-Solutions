// define as Starknet contract
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, storage_read, storage_write
from starkware.cairo.common.math import assert_not_zero, assert_nn_le, abs_value
from starkware.cairo.common.math_cmp import is_not_zero

// States
const GAME_NOT_STARTED = 0;
const P1_TURN = 1;
const P2_TURN = 2;
const P1_WIN = 3; 
const P2_WIN = 4; 
const TIE = 5;

// Max Move
const MAX_MOVE_INDEX = 8; 

@storage_var
func player_address(player_num: felt) -> (address: felt) {
}

@storage_var
func board(index: felt) -> (value: felt) {
}

@storage_var
func game_state() -> (value: felt) {
}

@view
func view_board {syscall_ptr: felt*, pedersen_ptr : HashBuiltin*, 
    range_check_ptr}() -> (b0 : felt, b1 : felt, b2 : felt,
    b3 : felt, b4 : felt, b5 : felt, b6 : felt, b7 : felt,
    b8 : felt) {
    let (b0) = board.read(index=0);
    let (b1) = board.read(index=1);
    let (b2) = board.read(index=2);
    let (b3) = board.read(index=3);
    let (b4) = board.read(index=4);
    let (b5) = board.read(index=5);
    let (b6) = board.read(index=6);
    let (b7) = board.read(index=7);
    let (b8) = board.read(index=8);
    return (b0, b1, b2, b3, b4, b5, b6, b7, b8);
}

@view
func get_game_state {syscall_ptr: felt*, pedersen_ptr : HashBuiltin*, 
    range_check_ptr}() -> (value: felt) {
    return game_state.read();
}

@external
func start_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    let (caller) = get_caller_address();
    player_address.write(player_num=1, value=caller); 
    return ();  
}

@external
func join{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(    
) {
    let (caller) = get_caller_address();
    player_address.write(player_num=2, value=caller);
    game_state.write(value=P1_TURN);
    return (); 
}

@external
func player_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player_num: felt, move_index: felt) {
    let (caller) = get_caller_address(); 
    let (curr_player_address) = player_address.read(player_num=player_num);
    assert curr_player_address = caller;
    
    let (turn) = game_state.read(); 
    assert turn = player_num;

    // verify index is valid and not set
    assert_nn_le(move_index, MAX_MOVE_INDEX);
    
    // verify index not already occupied
    let (index) = board.read(move_index); 
    assert index = 0; 
    
    // update board and game state
    update_game_state(move_index, turn); 
    return (); 
}

func update_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(move_index: felt, turn: felt) {
    // update board and get winner
    board.write(move_index, value=turn);
    let (new_winner) = get_winner(); 
    
    // handle player 2 win
    if (new_winner == 2) {
        game_state.write(value=P2_WIN); 
        return (); 
    }

    // handle player 1 win
    if (new_winner == 1) {
        game_state.write(value=P1_WIN); 
    } else {
        let (b0, b1, b2, b3, b4, b5, b6, b7, b8) = view_board(); 
        // handle board being full or switch turn
        if (b0 * b1 * b2 * b3 *b4 * b5 * b6 * b7 * b8 == 0) {
            let next_turn = P1_TURN + P2_TURN - turn; 
            game_state.write(value=next_turn); 
        } else {
            game_state.write(value=TIE); 
        }
    }
    return (); 
}

func get_winner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}() -> (winner: felt) {
    let (b0, b1, b2, b3, b4, b5, b6, b7, b8) = view_board();
    // check rows    
    if (abs_value(b0-b1)+abs_value(b1-b2) == 0 and b0 != 0) {
        return (winner = b0);
    }
    if (abs_value(b3-b4)+abs_value(b4-b5) == 0 and b3 != 0) {
        return (winner = b3);
    }
    if (abs_value(b6-b7)+abs_value(b7-b8) == 0 and b6 != 0) {
        return (winner = b6);
    } 

    // check cols 
    if (abs_value(b0-b3)+abs_value(b3-b6) == 0 and b0 != 0) {
        return (winner = b0);
    }
    if (abs_value(b1-b4)+abs_value(b4-b7) == 0 and b1 != 0) {
        return (winner = b1);
    }
    if (abs_value(b2-b5)+abs_value(b5-b8) == 0 and b2 != 0) {
        return (winner = b2);
    }

    // check diagonals 
    if (abs_value(b0-b4)+abs_value(b4-b8) == 0 and b0 != 0) {
        return (winner = b0);
    }
    if (abs_value(b2-b4)+abs_value(b4-b6) == 0 and b2 != 0) {
        return (winner = b2);
    }
    return (winner = 0); 
}