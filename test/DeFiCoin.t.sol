// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DeFiCoin.sol";

contract DeFiCoinTest is Test {
    DeFiCoin defiCoin;
    address owner = address(0x1);
    address addr1 = address(0x2);
    address addr2 = address(0x3);
    address addr3 = address(0x4);

    function setUp() public {
        vm.prank(owner);
        defiCoin = new DeFiCoin();
    }

    function test__AddToWhitelist() public {
        vm.prank(owner);
        defiCoin.addToWhiteList(addr1);

        assertEq(defiCoin.whitelistedAddresses(addr1), true);
    }

    function test__RemoveFromWhitelist() public {
        vm.prank(owner);
        defiCoin.addToWhiteList(addr1);

        vm.prank(owner);
        defiCoin.removeFromWhitelist(addr1);

        assertFalse(defiCoin.whitelistedAddresses(addr1));
    }
}
