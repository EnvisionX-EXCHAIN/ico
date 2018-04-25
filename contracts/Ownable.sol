pragma solidity ^0.4.20;

import "./GenesisProtected.sol";

// ----------------------------------------------------------------------------
// The original code is taken from:
// https://github.com/OpenZeppelin/zeppelin-solidity:
//     master branch from zeppelin-solidity/contracts/ownership/Ownable.sol
// Changed function name: transferOwnership -> setOwner.
// Added inheritance from GenesisProtected (address != 0x0).
// setOwner refactored for emitting event after owner replaced.
// ----------------------------------------------------------------------------

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is GenesisProtected {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a _new.
     * @param a is the address to transfer ownership to.
     */
    function setOwner(address a) external onlyOwner addrNotNull(a) {
        owner = a;
        emit OwnershipReplaced(msg.sender, a);
    }

    event OwnershipReplaced(
        address indexed previousOwner,
        address indexed newOwner
    );
}
