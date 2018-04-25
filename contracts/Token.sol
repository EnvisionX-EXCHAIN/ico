pragma solidity ^0.4.20;

import "./Enums.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20Interface.sol";
import "./WPTokensBaskets.sol";

contract Token is Ownable, ERC20Interface, Enums {
    using SafeMath for uint;

    // Token full name
    string private constant NAME = "EnvisionX EXCHAIN Token";
    // Token symbol name
    string private constant SYMBOL = "EXT";
    // Token max fraction, in decimal signs after the decimal
    uint8 private constant DECIMALS = 18;

    // Tokens max supply limit, in EXTwei
    uint public constant MAX_SUPPLY = 3000000000 * (10**uint(DECIMALS));

    // Tokens balances map
    mapping(address => uint) internal balances;

    // Maps with allowed amounts for TransferFrom
    mapping (address => mapping (address => uint)) internal allowed;

    // Total amount of issued tokens, in EXTwei
    uint internal _totalSupply;

    // Map of ETHs balances by address (using on refund)
    mapping(address => uint) internal etherFunds;
    uint internal _earnedFunds;
    // Map of refunded addresses that were blacklisted
    mapping(address => bool) internal refunded;

    // Address of sale agent (a contract) which can mint new tokens
    address public mintAgent;

    // Token transfer allowed only after token minting is finished
    bool public isMintingFinished = false;
    // Store the date when minting was finished
    uint public mintingStopDate;

    // Total amount of tokens minted to Team bin, in EXTwei.
    // This will not include tokens, transferred to Team bin
    // after minting is finished.
    uint public teamTotal;
    // Amount of tokens spent by Team within first 96 weeks
    // after minting finished date. Used to calculate Team spend
    // restrictions according to ICO White Paper.
    uint public spentByTeam;

    // Address of WPTokensBaskets contract
    WPTokensBaskets public wpTokensBaskets;

    // Constructor
    function Token(WPTokensBaskets baskets) public {
        wpTokensBaskets = baskets;
        mintAgent = owner;
    }

    // Fallback function - does not accept any ETH to this contract.
    function () external payable {
        revert();
    }

    // There are still few cases when ETHs can't be tokenized.
    // This function is to return those assets.
    // See the last warning at
    // http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function
    // for such cases.
    function transferEtherTo(address a) external onlyOwner addrNotNull(a) {
        a.transfer(address(this).balance);
    }

    /**
    ----------------------------------------------------------------------
    ERC20 Interface implementation
    */

    // Return token full name
    function name() public pure returns (string) {
        return NAME;
    }

    // Return token symbol name
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    // Return number of digits after the decimal point
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    // Return total amount of tokens issued so far, in EXTwei
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    // Return address balance in tokens (in EXTwei)
    function balanceOf(address _address) public constant returns (uint) {
        return balances[_address];
    }

    // Transfer tokens to another account
    function transfer(address to, uint value)
        public
        addrNotNull(to)
        returns (bool)
    {
        if (balances[msg.sender] < value)
            return false;
        if (isFrozen(wpTokensBaskets.typeOf(msg.sender), value))
            return false;
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        saveTeamSpent(msg.sender, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // Transfer tokens from one account to another,
    // using permissions defined with approve() method.
    function transferFrom(address from, address to, uint value)
        public
        addrNotNull(to)
        returns (bool)
    {
        if (balances[from] < value)
            return false;
        if (allowance(from, msg.sender) < value)
            return false;
        if (isFrozen(wpTokensBaskets.typeOf(from), value))
            return false;
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        saveTeamSpent(from, value);
        emit Transfer(from, to, value);
        return true;
    }

    // Allow to transfer given amount of tokens (in EXTwei)
    // to account which is not an owner.
    function approve(address spender, uint value) public returns (bool) {
        if (msg.sender == spender)
            return false;
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // Return amount of tokens (in EXTwei) which allowed to
    // be transferred by non-owner spender
    function allowance(address _owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowed[_owner][spender];
    }

    /**
    ----------------------------------------------------------------------
    Other methods
    */

    // Return account funds in ETH (in wei)
    function etherFundsOf(address _address) public constant returns (uint) {
        return etherFunds[_address];
    }

    // Return total amount of ETH funded so far (in wei)
    function earnedFunds() public constant returns (uint) {
        return _earnedFunds;
    }

    // Return true if given address have been refunded
    function isRefunded(address _address) public view returns (bool) {
        return refunded[_address];
    }

    // Set the address of sale agent contract.
    // Will be called for each sale stage: PrivateSale, PreSale, MainSale.
    function setMintAgent(address a) public onlyOwner addrNotNull(a) {
        emit MintAgentReplaced(mintAgent, a);
        mintAgent = a;
    }

    // Interface for sale agent contract - mint new tokens
    function mint(address to, uint256 extAmount, uint256 etherAmount) public {
        require(!isMintingFinished);
        require(msg.sender == mintAgent);
        require(!refunded[to]);
        _totalSupply = _totalSupply.add(extAmount);
        require(_totalSupply <= MAX_SUPPLY);
        balances[to] = balances[to].add(extAmount);
        if (wpTokensBaskets.isUnknown(to)) {
            _earnedFunds = _earnedFunds.add(etherAmount);
            etherFunds[to] = etherFunds[to].add(etherAmount);
        } else if (wpTokensBaskets.isTeam(to)) {
            teamTotal = teamTotal.add(extAmount);
        }
        emit Mint(to, extAmount);
        emit Transfer(msg.sender, to, extAmount);
    }

    // Destroy minted tokens and refund ethers spent by investor.
    // Created for AML (Anti Money Laundering) workflow.
    // Will be called only by humans because there is no way
    // to withdraw crowdfunded ether from Beneficiary account
    // from context of this account.
    // Important note: all tokens minted to team, foundation etc.
    // will NOT be burned, it's too expensive to track result of
    // each token minting transaction.
    function burnTokensAndRefund(address _address)
        external
        payable
        addrNotNull(_address)
        onlyOwner()
    {
        require(msg.value > 0 && msg.value == etherFunds[_address]);
        _totalSupply = _totalSupply.sub(balances[_address]);
        balances[_address] = 0;
        _earnedFunds = _earnedFunds.sub(msg.value);
        etherFunds[_address] = 0;
        refunded[_address] = true;
        _address.transfer(msg.value);
    }

    // Stop tokens minting forever
    function finishMinting() external onlyOwner {
        require(!isMintingFinished);
        isMintingFinished = true;
        mintingStopDate = now;
        emit MintingFinished();
    }

    /**
    ----------------------------------------------------------------------
    Tokens freeze logic, according to ICO White Paper
    */

    // Return truth if given _value amount of tokens (in EXTwei)
    // cannot be transferred from account due to spend restrictions
    // defined in ICO White Paper.
    // Current implementaion logic:
    // Say,
    //  1. There was 100 tokens minted to the Team basket;
    //  2. 24 weeks after minting finished team can spend up to 25 tokens
    //    within next 24 weeks;
    //  3. Someone transfers another 100 tokens to the team basket;
    //  4. Problem is, actually, you can't spend any of these extra 100
    //    tokens until 96 weeks will elapse since minting finish date.
    //    That's because there will be only 25 more tokens unfreezed
    //    in another 24 weeks (25% of *minted* tokens).
    // So, DO NOT send tokens to the Team basket after minting is finished.
    // It will not be available until 96 weeks have passed!
    function isFrozen(
        BasketType _basketType,
        uint _value
    )
        public view returns (bool)
    {
        if (!isMintingFinished) {
            // Allow spend only after minting is finished
            return true;
        }
        if (_basketType == BasketType.foundation) {
            // Allow to spend foundation tokens only after
            // 48 weeks after minting is finished
            return now < mintingStopDate + 48 weeks;
        }
        if (_basketType == BasketType.team) {
            // Team allowed to spend tokens:
            //  25%  - after minting finished date + 24 weeks;
            //  50%  - after minting finished date + 48 weeks;
            //  75%  - after minting finished date + 72 weeks;
            //  100% - after minting finished date + 96 weeks.
            if (mintingStopDate + 96 weeks <= now) {
                return false;
            }
            if (now < mintingStopDate + 24 weeks)
                return true;
            // Calculate fractionSpent as percents multipled to 10^10.
            // Without this owner will be able to spend fractions
            // less than 1% per transaction.
            uint fractionSpent =
                spentByTeam.add(_value).mul(1000000000000).div(teamTotal);
            if (now < mintingStopDate + 48 weeks) {
                return 250000000000 < fractionSpent;
            }
            if (now < mintingStopDate + 72 weeks) {
                return 500000000000 < fractionSpent;
            }
            // from 72 to 96 weeks elapsed
            return 750000000000 < fractionSpent;
        }
        // No restrictions for other token holders
        return false;
    }

    // Save amount of spent tokens by Team till 96 weeks after minting
    // finish date. This is vital because without the check we'll eventually
    // overflow the uint256.
    function saveTeamSpent(address _owner, uint _value) internal {
        if (wpTokensBaskets.isTeam(_owner)) {
            if (now < mintingStopDate + 96 weeks)
                spentByTeam = spentByTeam.add(_value);
        }
    }

    /**
    ----------------------------------------------------------------------
    Events
    */

    // Emitted when mint agent (address of a sale contract)
    // replaced with new one
    event MintAgentReplaced(
        address indexed previousMintAgent,
        address indexed newMintAgent
    );

    // Emitted when new tokens were created and funded to account
    event Mint(address indexed to, uint256 amount);

    // Emitted when tokens minting is finished.
    event MintingFinished();
}
