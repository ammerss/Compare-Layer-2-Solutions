from utils import *

# start game
output = estimate_fees_and_run(START_GAME)
start_game_hash = get_tx_hash(output)
print("P1 Joined Game")
print("Waiting for P2")

# join game
wait_until_accepted(start_game_hash)
output = estimate_fees_and_run(JOIN_GAME) 
join_game_hash = get_tx_hash(output)
print("P2 Joined Game")
print("Ready to Begin!")

# wait until join game finished
wait_until_accepted(join_game_hash)
moves = [[[2,0],[2,1],[2,2],[2,3],[1,3],[0,4],[6,0],[8,0],[3,5],[3,6],[3,7],[3,8],[2,6],[1,7],[1,8]],
        [[4,0],[4,1],[4,2],[4,3],[4,4],[4,5],[4,6],[4,7],[2,7],[2,8],[7,3],[7,4],[7,5],[5,6],[5,8]]]

# execute predefined player moves
for i in range(len(moves[0])):
    # play player 1 move and wait until accepted on L2
    p1_move_cmd = f"{PlAYER_MOVE} {moves[0][i][0]} {moves[0][i][1]} 0"
    p1_output = estimate_fees_and_run(p1_move_cmd)
    p1_tx_hash = get_tx_hash(p1_output)
    wait_until_accepted(p1_tx_hash)

    # play player 2 move and wait until accepted on L2
    p2_move_cmd = f"{PlAYER_MOVE} {moves[1][i][0]} {moves[1][i][1]} 1"
    p2_output = estimate_fees_and_run(p2_move_cmd)
    p2_tx_hash = get_tx_hash(p2_output)
    wait_until_accepted(p2_tx_hash)

# get board state
print(tx_finality_stats)
print(cost_stats)