pragma solidity ^0.4.20;

import "./Ownable.sol";

contract Killable is Ownable {
    // Inheritable function to delete a contract and send Ethereum from
    // the address of the contract to the specified address
    function kill(address a) external onlyOwner addrNotNull(a) {
        selfdestruct(a);
    }
}
