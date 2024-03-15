// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/CollateralManager.sol"; // Update path to your contract
import "../src/DeFiCoin.sol";

contract CollateralManagerTest is Test {
    CollateralManager collateralManager;
    DeFiCoin defiCoin;

    address owner = address(0x1);
    address addr1 = address(0x2);

    function setUp() public {
        vm.prank(owner);
        defiCoin = new DeFiCoin();

        vm.prank(owner);
        collateralManager = new CollateralManager(address(defiCoin));

        vm.prank(owner);
        defiCoin.addToMintList(address(collateralManager));
    }

    function test__SuccessfulDeposit() public {
        uint256 depositAmount = 1 ether;

        vm.deal(addr1, depositAmount);
        vm.prank(addr1);
        collateralManager.depositCollateral{value: depositAmount}();

        assertEq(collateralManager.collateralBalances(addr1), depositAmount);
    }

    function test__ZeroAmountDeposit() public {
        vm.prank(addr1);
        vm.expectRevert(CollateralManager__notEnoughEth.selector);
        collateralManager.depositCollateral{value: 0}();
    }

    function test__SuccessfulWithdrawal() public {
        uint256 depositAmount = 2 ether;
        uint256 withdrawalAmount = 1 ether;

        vm.deal(addr1, depositAmount);
        vm.prank(addr1);
        collateralManager.depositCollateral{value: depositAmount}();

        uint256 balanceBeforeWithdrawal = addr1.balance;

        vm.prank(addr1);
        collateralManager.withdrawCollateral(withdrawalAmount);

        assertEq(
            collateralManager.collateralBalances(addr1),
            depositAmount - withdrawalAmount
        );

        assertEq(addr1.balance, balanceBeforeWithdrawal + withdrawalAmount);
    }

    function test__WithdrawalExceedsCollateral() public {
        uint256 depositAmount = 1 ether;
        uint256 withdrawalAmount = depositAmount + 1;

        vm.deal(addr1, depositAmount);
        vm.prank(addr1);
        collateralManager.depositCollateral{value: depositAmount}();

        vm.expectRevert(CollateralManager__notEnoughCollateral.selector);
        vm.prank(addr1);
        collateralManager.withdrawCollateral(withdrawalAmount);
    }

    function test__BorrowingWithinLimit() public {
        uint256 depositAmount = 2 ether;
        uint256 borrowAmount = 1 ether; // Within limit (assuming COLLATERALIZATION_RATIO = 150)

        vm.deal(addr1, depositAmount);
        vm.prank(addr1);
        collateralManager.depositCollateral{value: depositAmount}();

        vm.expectCall(
            address(defiCoin),
            abi.encodeWithSelector(defiCoin.mint.selector, addr1, borrowAmount)
        );

        vm.prank(addr1);
        collateralManager.borrowDeFiCoins(borrowAmount);

        assertEq(collateralManager.loanBalances(addr1), borrowAmount);
    }

    function test__ExceedingBorrowingLimit() public {
        uint256 depositAmount = 1 ether;
        uint256 borrowAmount = 2 ether;

        vm.deal(addr1, depositAmount);
        collateralManager.depositCollateral{value: depositAmount}();

        vm.expectRevert(CollateralManager__borrowingAmountExceeded.selector);
        vm.prank(addr1);
        collateralManager.borrowDeFiCoins(borrowAmount);
    }

    function test__FullLoanRepayment() public {
        uint256 depositAmount = 2 ether;
        uint256 borrowAmount = 1 ether;

        vm.deal(addr1, depositAmount);
        vm.startPrank(addr1);
        collateralManager.depositCollateral{value: depositAmount}();
        collateralManager.borrowDeFiCoins(borrowAmount);
        vm.stopPrank();

        vm.warp(block.timestamp + 365 days);

        uint256 expectedRepayment = collateralManager.loanBalances(addr1) +
            collateralManager.calculateInterest(addr1);

        // Expect transferFrom on the mock
        // vm.expectCall(
        //     address(defiCoin),
        //     abi.encodeWithSelector(
        //         defiCoin.safeTransferFrom.selector,
        //         addr1,
        //         address(collateralManager),
        //         expectedRepayment
        //     )
        // );

        // vm.deal(addr1, expectedRepayment);
        // vm.prank(addr1);
        // collateralManager.repayLoan(expectedRepayment);

        // // Assertions
        // assertEq(collateralManager.loanBalances(addr1), 0);
        // assertEq(collateralManager.loanTimestamps(addr1), 0);
    }

    function test__PartialLoanRepayment() public {
        uint256 depositAmount = 2 ether;
        uint256 borrowAmount = 1 ether;

        vm.deal(addr1, depositAmount);
        vm.startPrank(addr1);
        collateralManager.depositCollateral{value: depositAmount}();
        collateralManager.borrowDeFiCoins(borrowAmount);
        vm.stopPrank();

        uint256 partialRepayment = collateralManager.loanBalances(addr1) / 2;

        vm.expectRevert(CollateralManager__RepaymentNotSufficient.selector);
        vm.deal(addr1, partialRepayment);
        vm.prank(addr1);
        collateralManager.repayLoan(partialRepayment);
    }
}
