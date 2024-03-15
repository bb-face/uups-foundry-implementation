// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error DeFiCoin__wrongSaleStage();
error DeFiCoin__notEnoughEth();
error DeFiCoin__notWhitelisted();
error DeFiCoin__maxTokenAllocationExceeded();
error DeFiCoin__cantMint();

contract DeFiCoin is ERC20, Ownable {
    uint256 public constant PRIVATE_SALE_PRICE = 0.0001 ether;
    uint256 public constant MAX_TOKEN_ALLOCATION = 1000;
    uint256 public constant PUBLIC_SALE_PRICE = 0.0002 ether;

    enum SaleStage {
        PrivateSale,
        PublicSale,
        SaleEnded
    }

    SaleStage public currentSaleStage = SaleStage.PrivateSale;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public canMint;

    constructor() Ownable(msg.sender) ERC20("DeFiCoin", "DFC") {}

    function mint(address to, uint256 amount) public {
        if (!canMint[msg.sender]) revert DeFiCoin__cantMint();
        _mint(to, amount);
    }

    function addToMintList(address _address) external onlyOwner {
        canMint[_address] = true;
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

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

    function addToWhiteList(address _address) external onlyOwner {
        whitelistedAddresses[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelistedAddresses[_address] = false;
    }

    function buyTokens() public payable {
        if (currentSaleStage == SaleStage.SaleEnded)
            revert DeFiCoin__wrongSaleStage();

        uint256 tokensToMint = 0;

        if (currentSaleStage == SaleStage.PrivateSale) {
            if (!whitelistedAddresses[msg.sender])
                revert DeFiCoin__notWhitelisted();

            tokensToMint = msg.value / PRIVATE_SALE_PRICE;

            if (tokensToMint > MAX_TOKEN_ALLOCATION)
                revert DeFiCoin__maxTokenAllocationExceeded();
        } else if (currentSaleStage == SaleStage.PublicSale) {
            tokensToMint = msg.value / PUBLIC_SALE_PRICE;
        }

        if (tokensToMint == 0) revert DeFiCoin__notEnoughEth();

        _mint(msg.sender, tokensToMint * 10 ** uint(decimals()));
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
