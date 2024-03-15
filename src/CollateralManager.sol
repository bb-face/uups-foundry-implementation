// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
        collateralBalances[msg.sender] += msg.value;
    }
}
