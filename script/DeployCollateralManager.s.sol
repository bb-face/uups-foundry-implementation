// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../src/CollateralManager.sol";
import "../src/CollateralManagerV2.sol";
import "../src/DeFiCoin.sol";

abstract contract DeployScript is Script {
    uint256 public immutable privateKey;
    address public implementation;
    address public proxyAddress;
    bytes public data;

    error InvalidAddress(string reason);

    modifier create() {
        _;
        if (implementation == address(0)) {
            revert InvalidAddress("implementation address can not be zero");
        }
        proxyAddress = address(new ERC1967Proxy(implementation, data));
    }

    modifier upgrade() {
        _;
        if (proxyAddress == address(0)) {
            revert InvalidAddress("proxy address can not be zero");
        }
        if (implementation == address(0)) {
            revert InvalidAddress("implementation address can not be zero");
        }
        UUPSUpgradeable proxy = UUPSUpgradeable(proxyAddress);
        proxy.upgradeToAndCall(address(implementation), data);
    }

    constructor(uint256 pkey) {
        privateKey = pkey;
    }

    function run() external {
        vm.startBroadcast(privateKey);
        _run();
        vm.stopBroadcast();
    }

    function _run() internal virtual;
}

contract DeployCollateralManager is DeployScript {
    constructor() DeployScript(vm.envUint("PRIVATE_KEY")) {}

    function _run() internal override create {
        DeFiCoin dc = new DeFiCoin();
        CollateralManager cm = new CollateralManager();

        bytes memory data = abi.encodeWithSelector(
            cm.initialize.selector,
            address(dc),
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );

        implementation = address(cm);
    }
}

contract DeployCollateralManagerV2 is DeployScript {
    constructor() DeployScript(vm.envUint("PRIVATE_KEY")) {
        proxyAddress = vm.envAddress("PROXY");
    }

    function _run() internal override upgrade {
        CollateralManagerV2 cm2 = new CollateralManagerV2();
        implementation = address(cm2);
        data = bytes.concat(cm2.upgradeVersion.selector);
    }
}
