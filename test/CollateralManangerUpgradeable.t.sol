// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CollateralManager.sol";
import "../src/CollateralManagerV2.sol";
import "../src/DeFiCoin.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract UUPSCounterTest is Test {
    address public cmAddr;
    address public cmAddrV2;
    address public proxy;
    address public owner = address(0x1);
    DeFiCoin dc;

    function setUp() public {
        dc = new DeFiCoin();
        CollateralManager cm = new CollateralManager();
        cmAddr = address(cm);
        bytes memory data = abi.encodeCall(cm.initialize, (address(dc), owner));
        proxy = address(new ERC1967Proxy(cmAddr, data));
    }

    function test__versionV1() public {
        uint version = CollateralManager(proxy).getVersion();
        assertEq(version, 1);
    }

    function test__versionV2() public {
        CollateralManagerV2 cm2 = new CollateralManagerV2();
        cmAddrV2 = address(cm2);
        vm.startPrank(owner);
        bytes memory data = abi.encodeCall(cm2.upgradeVersion, ());
        UUPSUpgradeable(proxy).upgradeToAndCall(cmAddrV2, data);

        uint version = CollateralManager(proxy).getVersion();
        vm.stopPrank();

        assertEq(version, 2);
    }
}
