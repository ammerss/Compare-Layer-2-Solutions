// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "hardhat/console.sol";
//https://github.com/chriseth/solidity-examples/blob/master/queue.sol 
////////////////////////////////////////////////////////////
// This is an example contract hacked together at a meetup.
// It is by far not complete and only used to show some
// features of Solidity.
////////////////////////////////////////////////////////////
library queue
{
    struct Queue {

        uint[999999999] data;
        uint front;
        uint back;
    }
    /// @dev the number of elements stored in the queue.
    function length(Queue storage q) view public returns (uint) {
        return q.back - q.front;
    }
    /// @dev push a new element to the back of the queue
    function push(Queue storage q, uint data) public
    {
        //if ((q.back + 1) % q.data.length == q.front) return; // throw;
        q.data[q.back] = data;
        q.back++;
        //q.back = (q.back + 1) % q.data.length;
    }
    /// @dev remove and return the element at the front of the queue
    
    function pop(Queue storage q) public returns (uint r)
    {
        if (q.back == q.front) revert(); // throw;
        r = q.data[q.front];
        delete q.data[q.front];
        q.front++;
        //q.front = (q.front + 1) % q.data.length;
    }

    function empty(Queue storage q) view public returns (bool){
        if (q.back - q.front <= 0) return true;
        else return false;
    }
}