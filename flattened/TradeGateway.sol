// File: node_modules\@openzeppelin\contracts\utils\Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts\TradeGateway.sol

pragma solidity ^0.6.0;



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
}

contract LevelupTradeGateway is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IBEP20 public TOKEN;
    
    uint256 public startDate = 1625716800;                  // July 8, 2021 01:00:00 AM UTC
    uint256 public tokenBuyPrice = 15 * 10**19;                // 1 BNB = 150 TOKEN when buy token
    uint256 public tokenSellPrice = 3 * 10**20;                // 1 BNB = 300 TOKEN when sell token

    bool public saleEnded;
    
    event tokensBought(address indexed user, uint256 amountSpent, uint256 amountBought, string tokenName, uint256 date);
    event tokensSold(address indexed user, uint256 amountSpent, uint256 amountSold, string tokenName, uint256 date);
    event tokensClaimed(address indexed user, uint256 amount, uint256 date);

    modifier checkBuyCondition(uint256 buyAmount) {
        require(now >= startDate, 'Trade not started');
        require(saleEnded == false, 'trade ended');
        require(
            buyAmount > 0 && buyAmount <= availableTokens(),
            'Insufficient buy amount'
        );
        _;
    }

    modifier checkSellCondition(uint256 sellAmount) {
        require(now >= startDate, 'Trade not started');
        require(saleEnded == false, 'trade ended');
        require(
            sellAmount > 0,
            'Insufficient sell amount'
        );
        _;
    }


    constructor(
        address _TOKEN        
    ) public {
        TOKEN = IBEP20(_TOKEN);
    }

    // Function to buy TOKEN using BNB token
    function buyToken(uint256 buyAmount) public nonReentrant payable checkBuyCondition(buyAmount) {
        uint256 amount = calculateBnbInBuy(buyAmount);
        require(msg.value >= amount, 'Insufficient BNB balance');
                
        TOKEN.transfer(msg.sender, buyAmount);
        emit tokensBought(msg.sender, amount, buyAmount, 'BNB', now);
    }

    // Function to sell TOKEN
    function sellToken(uint256 sellAmount) public nonReentrant payable checkSellCondition(sellAmount) {
        uint256 amount = calculateBnbInSell(sellAmount);
        require(address(this).balance >= amount, 'Insufficient BNB balance');
                
        TOKEN.transferFrom(msg.sender, address(this), sellAmount);
        msg.sender.transfer(amount);

        emit tokensSold(msg.sender, amount, sellAmount, 'BNB', now);
    }
    
    // function to set the presale start date
    // only owner can call this function
    function setStartDate(uint256 _startDate) public onlyOwner {
        require(saleEnded == false);
        startDate = _startDate;
    }

    // function to set the token buy price
    // only owner can call this function
    function setTokenBuyPrice(uint256 _tokenBuyPrice) public onlyOwner {
        require(_tokenBuyPrice > 0, "Invalid TOKEN Buy Price");
        tokenBuyPrice = _tokenBuyPrice;
    }

    // function to set the token sell price
    // only owner can call this function
    function setTokenSellPrice(uint256 _tokenSellPrice) public onlyOwner {
        require(_tokenSellPrice > 0, "Invalid TOKEN Sell Price");
        tokenSellPrice = _tokenSellPrice;
    }

    //function to end the sale
    //only owner can call this function
    function endSale() public onlyOwner {
        require(saleEnded == false, "Sale already ended");
        saleEnded = true;
    }

    //function to withdraw collected funds by the trade.
    //only owner can call this function
    function withdrawCollectedFunds() public nonReentrant onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        msg.sender.transfer(address(this).balance);
    }

    //function to withdraw available tokens
    //only owner can call this function
    function withdrawAvailableTokens() public nonReentrant onlyOwner {
        uint256 tokenBalance = availableTokens();
        require(tokenBalance > 0, "No remained tokens");
        TOKEN.transfer(msg.sender, tokenBalance);
    }

    //function to return the amount of unsold tokens
    function availableTokens() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    //function to calculate the buyable "tokenAmount" from bnb amount
    function calculateTokenInBuy(uint256 bnbAmount) public view returns (uint256) {
        uint256 tokenAmount = tokenBuyPrice.mul(bnbAmount).div(10**18);
        return tokenAmount;
    }

    //function to calculate the "tokenAmount" to be sold to get bnb amount
    function calculateTokenInSell(uint256 bnbAmount) public view returns (uint256) {
        uint256 tokenAmount = tokenSellPrice.mul(bnbAmount).div(10**18);
        return tokenAmount;
    }

    //function to calculate the bnb amount to buy "tokenAmount" of TOKEN 
    function calculateBnbInBuy(uint256 tokenAmount) public view returns (uint256) {
        require(tokenBuyPrice > 0, "TOKEN buy price should be greater than 0");
        uint256 bnbAmount = tokenAmount.mul(10**18).div(tokenBuyPrice);
        return bnbAmount;
    }

    //function to calculate the bnb amount to receive after sell "tokenAmount" of TOKEN
    function calculateBnbInSell(uint256 tokenAmount) public view returns (uint256) {
        require(tokenSellPrice > 0, "TOKEN sell price should be greater than 0");
        uint256 bnbAmount = tokenAmount.mul(10**18).div(tokenSellPrice);
        return bnbAmount;
    }
}
