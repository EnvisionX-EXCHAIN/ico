pragma solidity ^0.4.20;

import "./Killable.sol";

contract Beneficiary is Killable {

    // Address of account which will receive all ether
    // gathered from ICO
    address public beneficiary;

    // Constructor
    function Beneficiary() public {
        beneficiary = owner;
    }

    // Fallback function - do not apply any ether to this contract.
    function () external payable {
        revert();
    }

    // Set new beneficiary for ICO
    function setBeneficiary(address a) external onlyOwner addrNotNull(a) {
        beneficiary = a;
    }
}
