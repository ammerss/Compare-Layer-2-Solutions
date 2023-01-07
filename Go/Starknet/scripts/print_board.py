from utils import *

# initial board
board = [[-1 for _ in range(BOARD_Y)] for _ in range(BOARD_X)]
for i in range(BOARD_X): 
    for j in range(BOARD_Y): 
        # use call command to get board value at i,j
        gs_cmd = f"{GET_BOARD_AT} {i} {j}"
        output = subprocess_run(gs_cmd)
        # convert from 0-indexing and change EMPTY to "*"
        board[i][j] = str(int(output) + 1) if int(output) < 2 else "*"

# print board to console
print("********* BOARD *********")
for i in range(BOARD_X): 
    line = "["
    for j in range(BOARD_Y): 
        line += f"{board[i][j]} "
    print(line[:-1] + "]")
