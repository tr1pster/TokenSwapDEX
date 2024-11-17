pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TokenSwap {
    address public token1;
    address public token2;
    uint public totalLiquidity;
    mapping(address => uint) public liquidity;

    constructor(address _token1, address _token2) {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(uint _token1Amount, uint _token2Amount) public returns (uint liquidityAdded) {
        require(IERC20(token1).transferFrom(msg.sender, address(this), _token1Amount), "Transfer of token1 failed");
        require(IERC20(token2).transferFrom(msg.sender, address(this), _token2Amount), "Transfer of token2 failed");
        
        uint sumAmounts = _token1Amount + _token2Amount;
        if(totalLiquidity == 0) {
            totalLiquidity = sumAmounts;
        } else {
            totalLiquidity += sumAmounts / 2;
        }
        liquidityAdded = sumAmounts / 2;
        liquidity[msg.sender] += liquidityAdded;
        
        return liquidityAdded;
    }

    function removeLiquidity(uint _amount) public returns (uint token1Amount, uint token2Amount) {
        require(liquidity[msg.sender] >= _amount, "Not enough liquidity to withdraw");
        
        uint token1Balance = IERC20(token1).balanceOf(address(this));
        uint token2Balance = IERC20(token2).balanceOf(address(this));

        token1Amount = _amount * token1Balance / totalLiquidity;
        token2Amount = _amount * token2Balance / totalLiquidity;
        
        require(IERC20(token1).transfer(msg.sender, token1Amount), "Transfer of token1 failed");
        require(IERC20(token2).transfer(msg.sender, token2Amount), "Transfer of token2 failed");
        
        liquidity[msg.sender] -= _amount;
        totalLiquidity -= _amount;
    }

    function swap(address _fromToken, address _toToken, uint _amount) public {
        require(_fromToken == token1 || _fromToken == token2, "Invalid from token address");
        require(_toToken == token1 || _toToken == token2, "Invalid to token address");
        require(_fromToken != _toToken, "From and to tokens must be different");
        
        uint toTokenAmount = calculateSwapAmount(_fromToken, _toToken, _amount);
        
        require(IERC20(_fromToken).transferFrom(msg.sender, address(this), _amount), "Transfer of fromToken failed");
        require(IERC20(_toToken).transfer(msg.sender, toTokenAmount), "Transfer of toToken failed");
    }

    function calculateSwapAmount(address _fromToken, address _toToken, uint _amount) private view returns (uint toTokenAmount) {
        uint fromTokenBalance = IERC20(_fromToken).balanceOf(address(this));
        uint toTokenBalance = IERC20(_toToken).balanceOf(address(this));
        
        toTokenAmount = (_amount * toTokenBalance) / fromTokenBalance;
        return toTokenAmount;
    }

    function getBalances() public view returns (uint token1Balance, uint token2Balance) {
        token1Balance = IERC20(token1).balanceOf(address(this));
        token2Balance = IERC20(token2).balanceOf(address(this));
    }

    function getTotalLiquidity() public view returns (uint) {
        return totalLiquidity;
    }
}