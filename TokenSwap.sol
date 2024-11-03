pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenSwap {
    address public owner;
    IERC20 public token1;
    IERC20 public token2;
    uint256 public token1Reserve;
    uint256 public token2Reserve;
    uint256 public liquidity;
    mapping(address => uint256) public liquidityProviderBalance;

    constructor(address _token1, address _token2) {
        owner = msg.sender;
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function addLiquidity(uint256 _token1Amount, uint256 _token2Amount) external {
        token1.transferFrom(msg.sender, address(this), _token1Amount);
        token2.transferFrom(msg.sender, address(this), _token2Amount);
        token1Reserve += _token1Amount;
        token2Reserve += _token2Amount;

        uint256 liquidityMinted = _token1Amount + _token2Amount; // Simplified for this example
        liquidityProviderBalance[msg.sender] += liquidityMinted;
        liquidity += liquidityMinted;
    }

    function removeLiquidity(uint256 _amount) external {
        require(liquidityProviderBalance[msg.sender] >= _amount, "Not enough liquidity");
        uint256 token1Amount = _amount * token1Reserve / liquidity;
        uint256 token2Amount = _amount * token2Reserve / liquidity;

        liquidityProviderBalance[msg.sender] -= _amount;
        liquidity -= _amount;

        token1.transfer(msg.sender, token1Amount);
        token2.transfer(msg.sender, token2Amount);
    }

    
    function swapToken1ForToken2(uint256 _token1Amount) external {
        uint256 token2Amount = _token1Amount * token2Reserve / (token1Reserve + _token1Amount);
        token1.transferFrom(msg.sender, address(this), _token1Amount);
        token2.transfer(msg.sender, token2Amount);

        token1Reserve += _token1Amount;
        token2Reserve -= token2Amount;
    }

    function swapToken2ForToken1(uint256 _token2Amount) external {
        uint256 token1Amount = _token2Amount * token1Reserve / (token2Reserve + _token2Amount);
        token2.transferFrom(msg.sender, address(this), _token2Amount);
        token1.transfer(msg.sender, token1Amount);

        token2Reserve += _token2Amount;
        token1Reserve -= token1Amount;
    }

    function getLiquidity() external view returns (uint256) {
        return liquidity;
    }

    function getToken1Reserve() external view returns (uint256) {
        return token1Reserve;
    }

    function getToken2Reserve() external view returns (uint256) {
        return token2Reserve;
    }

}