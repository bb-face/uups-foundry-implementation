// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error DeFiCoin__WrongSaleStage();
error DeFiCoin__NotEnoughEth();
error DeFiCoin__NotWhitelisted();
error DeFiCoin__MaxTokenAllocationExceeded();
error DeFiCoin__CantMint();
error DeFiCoin__MaxSupplyReached();

contract DeFiCoin is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1000000 * (10 ** 18);
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

    constructor() Ownable(msg.sender) ERC20("DeFiCoin", "DFC") {
        addToMintList(owner());
    }

    function mint(address to, uint256 amount) public {
        if (totalSupply() + amount > MAX_SUPPLY)
            revert DeFiCoin__MaxSupplyReached();

        if (!canMint[msg.sender]) revert DeFiCoin__CantMint();

        _mint(to, amount);
    }

    function addToMintList(address addr) public onlyOwner {
        canMint[addr] = true;
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function startPublicSale() external onlyOwner {
        if (currentSaleStage != SaleStage.PrivateSale)
            revert DeFiCoin__WrongSaleStage();

        currentSaleStage = SaleStage.PublicSale;
    }

    function endSale() external onlyOwner {
        if (currentSaleStage != SaleStage.PublicSale)
            revert DeFiCoin__WrongSaleStage();

        currentSaleStage = SaleStage.SaleEnded;
    }

    function addToWhiteList(address addr) external onlyOwner {
        whitelistedAddresses[addr] = true;
    }

    function removeFromWhiteList(address addr) public onlyOwner {
        whitelistedAddresses[addr] = false;
    }

    function buyTokens() public payable {
        if (currentSaleStage == SaleStage.SaleEnded)
            revert DeFiCoin__WrongSaleStage();

        uint256 tokensToMint = 0;

        if (currentSaleStage == SaleStage.PrivateSale) {
            if (!whitelistedAddresses[msg.sender])
                revert DeFiCoin__NotWhitelisted();

            tokensToMint = msg.value / PRIVATE_SALE_PRICE;

            if (tokensToMint > MAX_TOKEN_ALLOCATION)
                revert DeFiCoin__MaxTokenAllocationExceeded();
        } else if (currentSaleStage == SaleStage.PublicSale) {
            tokensToMint = msg.value / PUBLIC_SALE_PRICE;
        }

        if (tokensToMint == 0) revert DeFiCoin__NotEnoughEth();

        _mint(msg.sender, tokensToMint * 10 ** uint(decimals()));
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
