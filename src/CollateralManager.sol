// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeFiCoin.sol";

error CollateralManager__notEnoughEth();
error CollateralManager__notEnoughCollateral();
error CollateralManager__notEnoughLoanBalance();
error CollateralManager__amountCantBeZero();
error CollateralManager__transferFailed();
error CollateralManager__borrowingAmountExceeded();
error CollateralManager__amountTooLow();

contract CollateralManager is Ownable {
    DeFiCoin public defiCoin;

    uint256 public constant COLLATERALIZATION_RATIO = 150;
    uint256 private constant ANNUAL_INTEREST_RATE = 10; //%

    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public loanBalances;
    mapping(address => uint256) public loanAmounts;
    mapping(address => uint256) public loanTimestamps;

    constructor() Ownable(msg.sender) {}

    function initialize(address _defiCoinAddress) public onlyOwner {
        defiCoin = DeFiCoin(_defiCoinAddress);
    }

    function depositCollateral() public payable {
        if (msg.value == 0) revert CollateralManager__notEnoughEth();
        collateralBalances[msg.sender] += msg.value;
    }

    function calculateBorrowLimit(address user) public view returns (uint256) {
        uint256 depositedEth = collateralBalances[user];
        return (depositedEth * COLLATERALIZATION_RATIO) / 100; // 100 -> %
    }

    function withdrawCollateral(uint256 amount) public {
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

    function borrow(uint256 amount) public {
        uint256 borrowingLimit = calculateBorrowLimit(msg.sender);

        if (amount > borrowingLimit)
            revert CollateralManager__borrowingAmountExceeded();

        loanAmounts[msg.sender] += amount;
        loanTimestamps[msg.sender] = block.timestamp;

        defiCoin.mint(msg.sender, amount);
    }

    function calculateInterest(address user) public view returns (uint256) {
        uint256 loanDurationInSeconds = block.timestamp - loanTimestamps[user];
        uint256 loanDurationInYears = loanDurationInSeconds / 365 days;
        uint256 interestAmount = (loanAmounts[user] *
            ANNUAL_INTEREST_RATE *
            loanDurationInYears) / 100;
        return interestAmount;
    }

    function repay(uint256 amount) public {
        uint256 interestAmount = calculateInterest(msg.sender);
        uint256 totalRepaymentAmount = loanAmounts[msg.sender] + interestAmount;

        if (amount < totalRepaymentAmount)
            revert CollateralManager__amountTooLow();

        defiCoin.burn(msg.sender, amount);

        // ?? check how to update these variables correctly:
        loanAmounts[msg.sender] = 0;
        loanTimestamps[msg.sender] = 0;
    }
}
