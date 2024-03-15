// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/ERC20.sol";

contract DeFiCoin is ERC20 {
    constructor() ERC20("DeFiCoin", "DFC") {
        _mint(msg.sender, 1000 * 10 ** uint(decimals()));
    }
}
