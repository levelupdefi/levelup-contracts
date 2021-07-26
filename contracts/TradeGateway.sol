pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
