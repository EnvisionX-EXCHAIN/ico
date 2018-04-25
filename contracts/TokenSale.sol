pragma solidity ^0.4.20;

import "./Killable.sol";
import "./Enums.sol";
import "./Beneficiary.sol";
import "./Token.sol";

contract TokenSale is Killable, Enums {
    using SafeMath for uint256;

    // Type describing:
    //  - the address of the beneficiary of the tokens;
    //  - the final amount of tokens calculated according to the
    //    terms of the WP;
    //  - the amount of ethers (in wei) if the Beneficiary is an Investor
    // This type is used in arrays[8] and should be declared in the contracts.
    struct tokens {
        address beneficiary;
        uint256 extAmount;
        uint256 ethAmount;
    }

    // Sale stage start date/time, Unix timestamp
    uint32 public start;
    // Sale stage stop date/time, Unix timestamp
    uint32 public stop;
    // Min ether amount for purchase
    uint256 public minBuyingAmount;
    // Price of one token, in wei
    uint256 public currentPrice;

    // Amount of tokens available, in EXTwei
    uint256 public remainingSupply;
    // Amount of earned funds, in wei
    uint256 public earnedFunds;

    // Address of Token contract
    Token public token;
    // Address of Beneficiary contract - a container
    // for the Beneficiary address
    Beneficiary internal _beneficiary;

    // Equals to 10^decimals.
    // Internally tokens stored as EXTwei (token count * 10^decimals).
    // Used to convert EXT to EXTwei and vice versa.
    uint256 internal dec;

    // Constructor
    function TokenSale(
        Token _token, // address of EXT ERC20 token contract
        Beneficiary beneficiary, // address of container for ether beneficiary
        uint256 _supplyAmount // in EXT
    )
        public
    {
        token = _token;
        _beneficiary = beneficiary;

        // Factor for convertation EXT to EXTwei and vice versa
        dec = 10 ** uint256(token.decimals());
        // convert to EXTwei
        remainingSupply = _supplyAmount.mul(dec);
    }

    // Fallback function. Here we'll receive all investments.
    function() external payable {
        purchase();
    }

    // Token purchase logic. Must be overrided in
    // arbitrary sale agent (per each sale stage).
    function purchase() public payable;

    // Return true if purchase with given _value of ether
    // (in wei) can be made
    function canPurchase(uint256 _value) public view returns (bool) {
        return start <= now && now <= stop &&
            minBuyingAmount <= _value &&
            toEXTwei(_value) <= remainingSupply;
    }

    // Return address of crowdfunding beneficiary account.
    function beneficiary() public view returns (address) {
        return _beneficiary.beneficiary();
    }

    // Return true if there are tokens available for purchase.
    function isActive() public view returns (bool) {
        return canPurchase(minBuyingAmount);
    }

    // Initialize tokensArray records with actual addresses of WP tokens baskets
    function setBaskets(tokens[8] memory _tokensArray) internal view {
        _tokensArray[uint8(BasketType.unknown)].beneficiary =
            msg.sender;
        _tokensArray[uint8(BasketType.team)].beneficiary =
            token.wpTokensBaskets().team();
        _tokensArray[uint8(BasketType.foundation)].beneficiary =
            token.wpTokensBaskets().foundation();
        _tokensArray[uint8(BasketType.arr)].beneficiary =
            token.wpTokensBaskets().arr();
        _tokensArray[uint8(BasketType.advisors)].beneficiary =
            token.wpTokensBaskets().advisors();
        _tokensArray[uint8(BasketType.bounty)].beneficiary =
            token.wpTokensBaskets().bounty();
    }

    // Return amount of tokens (in EXTwei) 
    // that corresponds to given amount of ethers (in wei) 
    // according to token price.
    function toEXTwei(uint256 _value) public view returns (uint256) {
        return _value.mul(dec).div(currentPrice);
    }

    // Receive amount of tokens (in EXTwei) that will be sold, and bonus percent
    // Return amount of bonus tokens (in EXTwei)
    function bonus(uint256 _tokens, uint8 _bonus)
        internal
        pure
        returns (uint256)
    {
        return _tokens.mul(_bonus).div(100);
    }

    // Initialize tokensArray records with actual amounts of tokens
    function calcWPTokens(tokens[8] memory a, uint8 _bonus) internal pure {
        a[uint8(BasketType.unknown)].extAmount =
           a[uint8(BasketType.unknown)].extAmount.add(
               bonus(
                   a[uint8(BasketType.unknown)].extAmount,
                   _bonus
               )
           );
        uint256 n = a[uint8(BasketType.unknown)].extAmount;
        a[uint8(BasketType.team)].extAmount = n.mul(24).div(40);
        a[uint8(BasketType.foundation)].extAmount = n.mul(20).div(40);
        a[uint8(BasketType.arr)].extAmount = n.mul(10).div(40);
        a[uint8(BasketType.advisors)].extAmount = n.mul(4).div(40);
        a[uint8(BasketType.bounty)].extAmount = n.mul(2).div(40);
    }

    // Send received ether (in wei) to beneficiary
    function transferFunds(uint256 _value) internal {
        beneficiary().transfer(_value);
        earnedFunds = earnedFunds.add(_value);
    }

    // Method for call mint() in EXT ERC20 contract.
    // mint() will be called for each record if amount of tokens > 0
    function createTokens(tokens[8] memory _tokensArray) internal {
        for (uint i = 0; i < _tokensArray.length; i++) {
            if (_tokensArray[i].extAmount > 0) {
                token.mint(
                    _tokensArray[i].beneficiary,
                    _tokensArray[i].extAmount,
                    _tokensArray[i].ethAmount
                );
            }
        }
    }
}
