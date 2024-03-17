// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./DeFiCoin.sol";

error CollateralManager__NotEnoughEth();
error CollateralManager__NotEnoughCollateral();
error CollateralManager__NotEnoughLoanBalance();
error CollateralManager__AmountCantBeZero();
error CollateralManager__TransferFailed();
error CollateralManager__BorrowingAmountExceeded();
error CollateralManager__RepayAmountExceedsTotalOwed();
error CollateralManager__RepaymentNotSufficient();

interface IDeFiCoin {
    function mint(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
}

contract CollateralManager is
    ReentrancyGuard,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IDeFiCoin public defiCoin;

    uint256 public constant COLLATERALIZATION_RATIO = 150;
    uint256 public constant ANNUAL_INTEREST_RATE = 10; //%
    uint256 public version;
    bool private initialized = false;

    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public loanBalances;
    mapping(address => uint256) public loanTimestamps;

    function initialize(
        address defiCoinAddress,
        address owner
    ) public initializer {
        OwnableUpgradeable.__Ownable_init(owner);
        version = 1;
        defiCoin = IDeFiCoin(defiCoinAddress);
    }

    function getVersion() public view returns (uint) {
        return version;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    function getLoanBalance(address addr) external view returns (uint) {
        return loanBalances[addr];
    }

    function depositCollateral() public payable {
        if (msg.value == 0) revert CollateralManager__NotEnoughEth();
        collateralBalances[msg.sender] += msg.value;
    }

    function withdrawCollateral(uint256 amount) public nonReentrant {
        if (amount == 0) revert CollateralManager__AmountCantBeZero();
        if (collateralBalances[msg.sender] < amount)
            revert CollateralManager__NotEnoughCollateral();

        uint256 newCollateralBalance = collateralBalances[msg.sender] - amount;

        uint256 maxLoanAllowedAfterWithdrawal = (newCollateralBalance *
            COLLATERALIZATION_RATIO) / 100;

        if (loanBalances[msg.sender] > maxLoanAllowedAfterWithdrawal)
            revert CollateralManager__NotEnoughLoanBalance();

        collateralBalances[msg.sender] = newCollateralBalance;

        (bool sent, ) = msg.sender.call{value: amount}("");

        if (!sent) revert CollateralManager__TransferFailed();
    }

    function calculateBorrowLimit(address user) public view returns (uint256) {
        return (collateralBalances[user] * COLLATERALIZATION_RATIO) / 100; // 100 -> %
    }

    function borrowDeFiCoins(uint256 amount) public nonReentrant {
        uint256 borrowingLimit = calculateBorrowLimit(msg.sender);

        if (amount > borrowingLimit)
            revert CollateralManager__BorrowingAmountExceeded();

        loanBalances[msg.sender] += amount;
        loanTimestamps[msg.sender] = block.timestamp;

        defiCoin.mint(msg.sender, amount);
    }

    function calculateInterest(address user) public view returns (uint256) {
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

        bool s = defiCoin.transferFrom(msg.sender, address(this), amount);

        if (!s) revert CollateralManager__TransferFailed();

        loanBalances[msg.sender] = 0;
        loanTimestamps[msg.sender] = 0;
    }
}
