// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Token is IERC20 {
    string public constant name = "Token";
    string public constant symbol = "TKN";
    uint8 public constant decimals = 18;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address public owner;

    // New variables for fee mechanism
    uint256 public transactionFeePercentage = 1; // 1% transaction fee
    address public feeDistributor; // This address is responsible for distributing fees

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        feeDistributor = msg.sender; // Initially setting the feeDistributor to the owner
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        _transfer(from, to, amount);
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(from, msg.sender, currentAllowance - amount);
        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Mint to the zero address");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Burn from the zero address");
        _burn(account, amount);
    }

    // Implementing fee redistribution
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");

        uint256 fee = (amount * transactionFeePercentage) / 100;
        uint256 amountAfterFee = amount - fee;

        _balances[from] = fromBalance - amount;
        _balances[to] += amountAfterFee;
        // Adding fee to feeDistributor's balance
        _balances[feeDistributor] += fee; 

        emit Transfer(from, to, amountAfterFee);
        if (fee > 0) {
            emit Transfer(from, feeDistributor, fee);
        }
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function updateFeeDistributor(address newFeeDistributor) external onlyOwner {
        require(newFeeDistributor != address(0), "FeeDistributor to the zero address");
        feeDistributor = newFeeDistributor;
    }

    function updateTransactionFeePercentage(uint256 newFeePercentage) external onlyOwner {
        transactionFeePercentage = newFeePercentage;
    }
}