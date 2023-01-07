import subprocess
import time 

# define contract address and board dimension
CONTRACT_ADDRESS = "0x03af4983afdb58005d63cfeb52135bd42d7b0c65888ff2abc21c331997d2015f"
BOARD_X, BOARD_Y = 11,11

# define commands for all contract interactions
START_GAME = f"starknet invoke --address {CONTRACT_ADDRESS} --abi Go_abi.json --function start_game --inputs {BOARD_X} {BOARD_Y}"
JOIN_GAME = f"starknet invoke --address {CONTRACT_ADDRESS} --abi Go_abi.json --function join"
RESET_BOARD = f"starknet invoke --address {CONTRACT_ADDRESS} --abi tic_contract_abi.json --function reset_game"
PlAYER_MOVE = f"starknet invoke --address {CONTRACT_ADDRESS} --abi Go_abi.json --function player_move --inputs"
GET_BOARD_AT = f"starknet call --address {CONTRACT_ADDRESS} --abi Go_abi.json --function get_board_at --inputs"
GET_GAME_STATE = f"starknet call --address {CONTRACT_ADDRESS} --abi Go_abi.json --function get_game_state --inputs"
STARKNET_TX_STATUS = f"starknet tx_status --hash"
ESTIMATE_FEE = "--estimate_fee"

# lists to store finality times and estimated costs 
tx_finality_stats = []
cost_stats = []

# wrap around subprocess to get output
def subprocess_run(cmd):
	result = subprocess.run(cmd.split(" "), stdout=subprocess.PIPE)
	result = result.stdout.decode('utf-8')[:-1] # remove trailing newline
	return result

# given output from invoke command, fetch transaction hash
def get_tx_hash(output): 
    term = "transactionhash"
    for line in output.split("\n"): 
        line = line.replace(" ", "").lower()
        if term in line: 
            tx_hash = line[line.index(":")+1:]
            return tx_hash
    return ""

# given output from tx_status command, 
# check if transaction status is "ACCEPTED_ON_L2"
def get_tx_status(status_output): 
    line_term = "tx_status"
    status_term = "accepted_on_l2"
    for line in status_output.split("\n"): 
        line = line.replace(" ", "").lower()
        if line_term in line: 
            return status_term in line
    return False

# continuously query tx_status command until 
# transaction status is "ACCEPTED_ON_L2"
def wait_until_accepted(tx_hash):
    cmd = f"{STARKNET_TX_STATUS} {tx_hash}"
    count = 0
    while (True): 
        # query tx status
        status_output = subprocess_run(cmd)
        status = get_tx_status(status_output)
        if (status): 
            # print and store finality
            print(f"Accepted on L2 in {count / 2} seconds")
            tx_finality_stats.append(count / 2)
            # sleep for additional second
            time.sleep(1)
            break
        if (count % 20 == 0): 
            print(f"Waiting for tx to be accepted - {count / 2} seconds complete.")
            print(f"Tx Hash - {tx_hash}")
        # retry every 0.5 seconds
        time.sleep(0.5)
        count += 1

# given output from estimated_fee, parse fee
# gas cost and gas usage 
def store_estimated_fee(output):
    nums = []
    for line in output.split("\n"): 
        line = line.replace(" ", "")
        nums.append(line[line.index(":")+1:])
    fee = nums[0][:nums[0].index("WEI")]
    gas_usage = nums[1]
    gas_cost = nums[2][:nums[2].index("WEI")]
    # store cost stats
    cost_stats.append((fee, gas_usage, gas_cost))
    return fee

# execute estimate_fee and then run the invoke command
def estimate_fees_and_run(cmd): 
    output = subprocess_run(f"{cmd} {ESTIMATE_FEE}")
    store_estimated_fee(output)
    return subprocess_run(cmd)