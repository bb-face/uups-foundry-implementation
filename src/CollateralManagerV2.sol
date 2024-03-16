// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./CollateralManager.sol";

contract CollateralManagerV2 is CollateralManager {
    function upgradeVersion() public {
        version = 2;
    }
}
