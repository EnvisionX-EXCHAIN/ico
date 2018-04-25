pragma solidity ^0.4.20;

import "./Ownable.sol";
import "./Enums.sol";

contract WPTokensBaskets is Ownable, Enums {
    // This mapping holds all accounts ever used as targeted bins forever
    mapping (address => BasketType) internal types;

    // Bins for tokens
    address public team;
    address public foundation;
    address public arr;
    address public advisors;
    address public bounty;

    // Public constructor
    function WPTokensBaskets(
        address _team,
        address _foundation,
        address _arr,
        address _advisors,
        address _bounty
    )
        public
    {
        setTeam(_team);
        setFoundation(_foundation);
        setARR(_arr);
        setAdvisors(_advisors);
        setBounty(_bounty);
    }

    // Fallback function - does not accept any ether to this contract.
    function () external payable {
        revert();
    }

    // There are still few cases when ETHs can't be tokenized.
    // See the last warning at
    // http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function
    // for such cases.
    function transferEtherTo(address a) external onlyOwner addrNotNull(a) {
        a.transfer(address(this).balance);
    }

    // Return bin type for given address
    function typeOf(address a) public view returns (BasketType) {
        return types[a];
    }

    // Return true if given address is not a token bin.
    function isUnknown(address a) public view returns (bool) {
        return types[a] == BasketType.unknown;
    }

    // Return true if given address is Team tokens bin
    function isTeam(address a) public view returns (bool) {
        return types[a] == BasketType.team;
    }

    // Return true if given address is Foundation tokens bin
    function isFoundation(address a) public view returns (bool) {
        return types[a] == BasketType.foundation;
    }

    // Function for set Team tokens bin address
    function setTeam(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[team = a] = BasketType.team;
    }

    // Function for set Foundation tokens bin address
    function setFoundation(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[foundation = a] = BasketType.foundation;
    }

    // Function for set Advertisement/Referral/Reward tokens bin address
    function setARR(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[arr = a] = BasketType.arr;
    }

    // Function for set Advisors tokens bin address
    function setAdvisors(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[advisors = a] = BasketType.advisors;
    }

    // Function for set Bounty tokens bin address
    function setBounty(address a) public onlyOwner addrNotNull(a) {
        require(types[a] == BasketType.unknown);
        types[bounty = a] = BasketType.bounty;
    }
}
