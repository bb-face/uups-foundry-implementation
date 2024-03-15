// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error DeFiCoin__wrongSaleStage();
error DeFiCoin__notEnoughEth();

contract DeFiCoin is ERC20, Ownable {
    uint256 public privateSalePrice = 0.0001 ether;
    uint256 public publicSalePrice = 0.0002 ether;

    enum SaleStage {
        PrivateSale,
        PublicSale,
        SaleEnded
    }

    SaleStage public currentSaleStage = SaleStage.PrivateSale;

    constructor() Ownable(msg.sender) ERC20("DeFiCoin", "DFC") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    // function transfer(address recipient, uint256 amount) public virtual override returns (bool);

    function startPublicSale() external onlyOwner {
        if (currentSaleStage != SaleStage.PrivateSale)
            revert DeFiCoin__wrongSaleStage();

        currentSaleStage = SaleStage.PublicSale;
    }

    function endSale() external onlyOwner {
        if (currentSaleStage != SaleStage.PublicSale)
            revert DeFiCoin__wrongSaleStage();

        currentSaleStage = SaleStage.SaleEnded;
    }

    function buyTokens() public payable {
        if (currentSaleStage == SaleStage.SaleEnded)
            revert DeFiCoin__wrongSaleStage();

        uint256 tokensToMint = 0;

        if (currentSaleStage == SaleStage.PrivateSale) {
            tokensToMint = msg.value / privateSalePrice;
        } else if (currentSaleStage == SaleStage.PublicSale) {
            tokensToMint = msg.value / publicSalePrice;
        }

        if (tokensToMint == 0) revert DeFiCoin__notEnoughEth();

        _mint(msg.sender, tokensToMint * 10 ** uint(decimals()));
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
