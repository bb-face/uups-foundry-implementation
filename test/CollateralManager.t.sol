// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/CollateralManager.sol"; // Update path to your contract

contract CollateralManagerTest is Test {
    CollateralManager collateralManager;
    address owner = address(0x1);
    address addr1 = address(0x2);

    function setUp() public {
        collateralManager = new CollateralManager(address(0));
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
}
