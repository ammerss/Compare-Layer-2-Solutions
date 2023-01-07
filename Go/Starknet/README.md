# Go on StarkNet
This directory contains the Cairo contract, unit tests and driver scripts for running Go on StarkNet Testnet. Cairo does not support loops, so a lot of functions are implemented recursively.  

# Executing Contract
Setup an account on Starknet along with the required environment variables as described here - https://starknet.io/docs/hello_starknet/account_setup.html. Then in the scripts folder run "run_game.py" to execute a sample game with 20 pre-defined moves. This script can be modified as required to investigate how the contract behaves. All functions annotated with @external or @view tags can be invoked or called. 

# Local Testing
In the tests folder modify tests.py to perform any unit tests locally. To compile Cairo code, find instructions here - https://starknet.io/docs/quickstart.html#quickstart 


