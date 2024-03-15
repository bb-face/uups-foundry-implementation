// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeFiCoin is ERC20, Ownable {
    constructor() Ownable(msg.sender) ERC20("DeFiCoin", "DFC") {
        _mint(msg.sender, 1000 * 10 ** uint(decimals()));
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    // function transfer(address recipient, uint256 amount) public virtual override returns (bool);
}
