pragma solidity ^0.4.20;

import "./TokenSale.sol";

contract PrivateSale is TokenSale {
    using SafeMath for uint256;

    // List of investors allowed to buy tokens at PrivateSale
    mapping(address => bool) internal allowedInvestors;

    // Constructor
    function PrivateSale(Token _token, Beneficiary _beneficiary)
        TokenSale(_token, _beneficiary, uint256(400000000))
        public
    {
        start = 1522627620;
        stop = 1525046399;
        minBuyingAmount = 70 szabo;
        currentPrice = 70 szabo;
    }

    // Purchase logic
    function purchase() public payable {
        require(isInvestorAllowed(msg.sender));
        require(canPurchase(msg.value));
        transferFunds(msg.value);
        tokens[8] memory tokensArray;
        tokensArray[uint8(BasketType.unknown)].extAmount = toEXTwei(msg.value);
        setBaskets(tokensArray);
        remainingSupply = remainingSupply.sub(
            tokensArray[uint8(BasketType.unknown)].extAmount
        );
        calcWPTokens(tokensArray, 30);
        tokensArray[uint8(BasketType.unknown)].ethAmount = msg.value;
        createTokens(tokensArray);
    }

    // Register new investor
    function allowInvestor(address a) public onlyOwner addrNotNull(a) {
        allowedInvestors[a] = true;
    }

    // Discard existing investor
    function denyInvestor(address a) public onlyOwner addrNotNull(a) {
        delete allowedInvestors[a];
    }

    // Return true if given account is allowed to buy tokens
    function isInvestorAllowed(address a) public view returns (bool) {
        return allowedInvestors[a];
    }
}
