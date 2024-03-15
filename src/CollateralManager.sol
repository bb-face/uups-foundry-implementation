// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error CollateralManager__notEnoughEth();
error CollateralManager__notEnoughCollateral();
error CollateralManager__notEnoughLoanBalance();
error CollateralManager__amountCantBeZero();
error CollateralManager__transferFailed();

contract CollateralManager is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public defiCoin;

    uint256 public constant COLLATERALIZATION_RATIO = 150;

    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public loanBalances;

    constructor() Ownable(msg.sender) {}

    function initialize(address _defiCoinAddress) public onlyOwner {
        defiCoin = IERC20(_defiCoinAddress);
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
}
