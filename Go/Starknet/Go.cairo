%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, storage_read, storage_write
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.math_cmp import is_nn_le

// board values
const UNCHECKED = 0; 
const CHECKED = 1; 
const EMPTY = 2; 

// states
const P1_TURN = 0; 
const P2_TURN = 1; 
const GAME_OVER = 2; 
const GAME_NOT_STARTED = 3; 

// board versions
const BACKUP = -1; 
const CURR = 0; 
const TEST = 1; 

// main boards (test, current and backup)
@storage_var
func board(index: felt, version: felt) -> (value: felt) {
}

// check board to compute liberties
@storage_var
func check_board(index: felt) -> (value: felt) {
}

// store current player
@storage_var
func game_state() -> (state: felt) {
}

// store board dimension
@storage_var
func board_size() -> (dims: (felt, felt)) {
}

// get board value at x and y
@view
func get_board_at{syscall_ptr: felt*, pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(x: felt, y: felt) -> (value: felt) {
    // read board dimensions
    let (dims) = board_size.read(); 
    tempvar idx = x * dims[1] + y; 
    tempvar MAX_IDX = dims[0] * dims[1]; 
    
    // verify index is valid
    assert_nn_le(idx, MAX_IDX - 1);
    return board.read(idx, CURR); 
}

// get current game state
@view
func get_game_state{syscall_ptr: felt*, pedersen_ptr : HashBuiltin*, 
    range_check_ptr}() -> (state: felt) {
    return game_state.read(); 
}

// start game as player 1, with provided board size
@external
func start_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(board_x: felt, board_y: felt) -> () {
    // update game state and board size
    game_state.write(value=GAME_NOT_STARTED);
    board_size.write(value=(board_x, board_y)); 
    // initialize boards
    tempvar MAX_IDX = board_x * board_y; 
    init_boards(0, MAX_IDX);  
    return ();
}

// join game as player 2
@external
func join{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}() -> () {
    // assert state
    let (state) = game_state.read(); 
    assert state = GAME_NOT_STARTED; 

    // update state
    game_state.write(value=P1_TURN); 
    return ();
}

// reset boards and game state
@external
func reset_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}() -> () {
    // update game state
    game_state.write(value=GAME_NOT_STARTED);
    let (dims) = board_size.read(); 
    tempvar MAX_IDX = dims[0] * dims[1]; 
    // note -> might not be neccessary
    init_boards(0, MAX_IDX);  
    return ();
}

// initialize boards recursievly
func init_boards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, MAX_IDX: felt) {
    // base case
    if (idx == MAX_IDX) {
        return (); 
    }
    // set initial values for all boards
    board.write(idx, BACKUP, value=EMPTY);
    board.write(idx, CURR, value=EMPTY);
    board.write(idx, TEST, value=EMPTY);
    check_board.write(idx, value=UNCHECKED);
    // recursive call 
    init_boards(idx + 1, MAX_IDX); 
    return (); 
}

// submit a move from a player
@external
func player_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(x: felt, y: felt, player_num: felt) -> (valid: felt) {
    // check that turn is correct
    let (turn) = game_state.read();
    assert turn = player_num;  

    // get board dimensions
    let (dims) = board_size.read(); 
    tempvar MAX_IDX = dims[0] * dims[1];

    // check that location is empty
    let (tval) = board.read(x * dims[1] + y, TEST);  
    assert tval = EMPTY;
    
    // update game state if move is valid
    return update_game_state(x * dims[1] + y, player_num, MAX_IDX); 
}

// update game state according to a move
func update_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, turn: felt, MAX_IDX:felt) -> (valid: felt) {
    alloc_locals; 

    // write to test board and clear
    board.write(idx, TEST, value=turn);
    clear_board(0, TEST, MAX_IDX);

    // check if move is invalid
    let (local board_invalid) = is_test_board_invalid(0, MAX_IDX); 
    let (local invalid_move) = is_move_invalid(idx, MAX_IDX); 
    if (board_invalid + invalid_move != 0) {
        // reset test board and return invalid move
        copy_board(0, CURR, TEST, MAX_IDX); 
        return (valid = 0); 
    }
    // valid move -> update backup board and board 
    copy_board(0, CURR, BACKUP, MAX_IDX); 
    copy_board(0, TEST, CURR, MAX_IDX); 

    // update turn and return valid move
    game_state.write(value = 1-turn); 
    return (valid=1); 
}

// check if a move is within the range of the board
func is_within_bounds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr} (idx: felt, MAX_IDX: felt) -> (within_bounds: felt) {
    // return 0 if within MAX_IDX
    if (is_nn_le(idx, MAX_IDX - 1) == 0) {
        return (within_bounds = 0);
    }
    return (within_bounds = 1);
}

// check if test board reverted to backup board
func is_test_board_invalid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, MAX_IDX:felt) -> (res: felt) {
    // reached end -> move is invalid
    if (idx == MAX_IDX) {
        return (res=1);
    }
    // compare test and backup board at current idx
    let (tval) = board.read(idx, TEST); 
    let (bbval) = board.read(idx, BACKUP); 

    // not equal -> move is valid
    if (tval != bbval) {
        return (res=0); 
    }
    return is_test_board_invalid(idx+1, MAX_IDX); 
}

// check if a move is valid and reset checkboard if so
func is_move_invalid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, MAX_IDX:felt) -> (res: felt) {
    alloc_locals; 
    let (local tval) = board.read(idx, TEST); 
    let (local liberties) = get_liberties(idx, TEST, MAX_IDX); 
    // if not empty and zero liberties -> invalid move
    if (tval != EMPTY and liberties == 0) {
        return (res=1); 
    }
    // valid move
    reset_check_board(0, MAX_IDX); 
    return (res=0);
}

// remove stones captured by current player from board
func clear_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, version: felt, MAX_IDX:felt) {
    alloc_locals; 
    // base case
    if (idx == MAX_IDX) {
        return (); 
    }

    let (local bval) = board.read(idx, version); 
    let (local player) = game_state.read(); 
    // check if opposing player stone
    if (bval != EMPTY and bval != player) {
        // get liberties
        let (liberties) = get_liberties(idx, version, MAX_IDX); 
        if (liberties == 0) {
            // no liberties, so compute chain and remove all
            reset_chain(0, version, MAX_IDX);
            reset_check_board(0, MAX_IDX);
            clear_board(idx + 1, version, MAX_IDX); 
            return (); 
        } else {
            // some liberties present, so reset checkboard and call recursively
            reset_check_board(0, MAX_IDX);
            clear_board(idx + 1, version, MAX_IDX); 
            return ();  
        }
    }
    // not an opposing player stone, call recursively
    clear_board(idx + 1, version, MAX_IDX); 
    return ();
}

// resets all checkboard stones to UNCHECKED
func reset_check_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, MAX_IDX) {
    // base case
    if (idx == MAX_IDX) { 
        return ();
    }
    // write to unchecked and call recursively
    check_board.write(idx, value=UNCHECKED); 
    reset_check_board(idx + 1, MAX_IDX); 
    return (); 
}

// copies one board to another
func copy_board{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, from_version: felt, 
    to_version: felt, MAX_IDX:felt) {
    // base case
    if (idx == MAX_IDX) {
        return (); 
    }

    // read and update storage variables
    let (from_val) = board.read(idx, from_version); 
    board.write(idx, to_version, value=from_val);
    // call recursively 
    copy_board(idx+1, from_version, to_version, MAX_IDX); 
    return (); 
}

// compute liberties for given index
func get_liberties{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, version: felt, MAX_IDX: felt) -> (count: felt) {  
    alloc_locals; 
    let (within_bounds) = is_within_bounds(idx, MAX_IDX);    
    if (within_bounds == 0) {
        return (count=0); 
    }

    let (bval) = board.read(idx, version); 
    let (cval) = check_board.read(idx);     
    if (bval == EMPTY) {
        return (count=-1); 
    }
    if (cval == CHECKED) {
        return (count=0); 
    }
    check_board.write(idx, value=CHECKED); 
    
    let (dims) = board_size.read(); 
    let (local p1_val) = get_lib_value(idx, idx+1, version, MAX_IDX); 
    let (local p2_val) = get_lib_value(idx, idx-1, version, MAX_IDX); 
    let (local p3_val) = get_lib_value(idx, idx+dims[1], version, MAX_IDX); 
    let (local p4_val) = get_lib_value(idx, idx-dims[1], version, MAX_IDX); 
    let res = p1_val + p2_val + p3_val + p4_val; 
    return (count=res); 
}

// helper function to compute liberties
func get_lib_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx: felt, pidx: felt, version: felt, MAX_IDX:felt) -> (count: felt) { 
    let (within_bounds) = is_within_bounds(pidx, MAX_IDX);    
    if (within_bounds == 0) {
        return (count=0); 
    }

    let (bval) = board.read(idx, version);
    let (val) = board.read(pidx, version);
    if (val == EMPTY) {
        return (count=1); 
    }
    if (val == bval) {
        let (liberties) = get_liberties(pidx, version, MAX_IDX);
        check_board.write(pidx, value=CHECKED); 
        return (count=liberties);  
    }
    return (count=0); 
}

// reset a chain of 0 liberty values of opposing player stones
func reset_chain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, 
    range_check_ptr}(idx : felt, version: felt, MAX_IDX:felt) {
    if (idx == MAX_IDX) {
        return (); 
    }

    let (cval) = check_board.read(idx); 
    if (cval == CHECKED) {
        board.write(idx, version, value=EMPTY);
        reset_chain(idx + 1, version, MAX_IDX);
        return ();   
    } 
    
    reset_chain(idx + 1, version, MAX_IDX); 
    return (); 
}