pragma solidity ^0.4.20;

// Contract with modifier for genesis address protection
contract GenesisProtected {
    modifier addrNotNull(address _address) {
        require(_address != address(0));
        _;
    }
}
