// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./DeFiCoin.sol";

error CollateralManager__notEnoughEth();
error CollateralManager__notEnoughCollateral();
error CollateralManager__notEnoughLoanBalance();
error CollateralManager__amountCantBeZero();
error CollateralManager__transferFailed();
error CollateralManager__borrowingAmountExceeded();
error CollateralManager__RepayAmountExceedsTotalOwed();
error CollateralManager__RepaymentNotSufficient();

interface IDeFiCoin {
    function mint(address to, uint256 amount) external;

    function transferFrom(address from, address to, uint amount) external;
}

contract CollateralManager is ReentrancyGuard {
    IDeFiCoin public defiCoin;

    uint256 public constant COLLATERALIZATION_RATIO = 150;
    uint256 public constant ANNUAL_INTEREST_RATE = 10; //%

    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public loanBalances;
    mapping(address => uint256) public loanTimestamps;

    constructor(address _defiCoinAddress) {
        defiCoin = IDeFiCoin(_defiCoinAddress);
    }

    function getLoanBalance(address _address) external view returns (uint) {
        return loanBalances[_address];
    }

    function depositCollateral() public payable {
        if (msg.value == 0) revert CollateralManager__notEnoughEth();
        collateralBalances[msg.sender] += msg.value;
    }

    function withdrawCollateral(uint256 amount) public nonReentrant {
        if (amount == 0) revert CollateralManager__amountCantBeZero();
        if (collateralBalances[msg.sender] < amount)
            revert CollateralManager__notEnoughCollateral();

        uint256 newCollateralBalance = collateralBalances[msg.sender] - amount;

        uint256 maxLoanAllowedAfterWithdrawal = (newCollateralBalance *
            COLLATERALIZATION_RATIO) / 100;

        if (loanBalances[msg.sender] > maxLoanAllowedAfterWithdrawal)
            revert CollateralManager__notEnoughLoanBalance();

        collateralBalances[msg.sender] = newCollateralBalance;

        (bool sent, ) = msg.sender.call{value: amount}("");

        if (!sent) revert CollateralManager__transferFailed();
    }

    function calculateBorrowLimit(address user) public view returns (uint256) {
        return (collateralBalances[user] * COLLATERALIZATION_RATIO) / 100; // 100 -> %
    }

    function borrowDeFiCoins(uint256 amount) public nonReentrant {
        uint256 borrowingLimit = calculateBorrowLimit(msg.sender);

        if (amount > borrowingLimit)
            revert CollateralManager__borrowingAmountExceeded();

        loanBalances[msg.sender] += amount;
        loanTimestamps[msg.sender] = block.timestamp;

        defiCoin.mint(msg.sender, amount);
    }

    function calculateInterest(address user) public view returns (uint256) {
        if (loanTimestamps[user] == 0) return 0;

        uint256 loanDurationInSeconds = block.timestamp - loanTimestamps[user];
        uint256 loanDurationInYears = loanDurationInSeconds /
            (365 * 24 * 60 * 60);
        uint256 interest = (loanBalances[user] *
            (ANNUAL_INTEREST_RATE / 100) *
            loanDurationInYears) / 100;

        return interest;
    }

    function repayLoan(uint256 amount) public nonReentrant {
        uint256 totalOwed = loanBalances[msg.sender] +
            calculateInterest(msg.sender);

        if (amount < totalOwed) {
            revert CollateralManager__RepaymentNotSufficient();
        } else if (amount > totalOwed) {
            revert CollateralManager__RepayAmountExceedsTotalOwed();
        }

        defiCoin.transferFrom(msg.sender, address(this), amount);

        loanBalances[msg.sender] = 0;
        loanTimestamps[msg.sender] = 0;
    }
}
