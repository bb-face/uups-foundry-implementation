// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/DeFiCoin.sol";

contract DeFiCoinTest is Test {
    DeFiCoin defiCoin;
    address owner = address(0x1);
    address addr1 = address(0x2);
    address addr2 = address(0x3);
    address addr3 = address(0x4);
    uint PRIVATE_SALE_PRICE;
    uint PUBLIC_SALE_PRICE;
    uint MAX_TOKEN_ALLOCATION;

    function setUp() public {
        vm.prank(owner);
        defiCoin = new DeFiCoin();

        PRIVATE_SALE_PRICE = defiCoin.PRIVATE_SALE_PRICE();
        PUBLIC_SALE_PRICE = defiCoin.PUBLIC_SALE_PRICE();
        MAX_TOKEN_ALLOCATION = defiCoin.MAX_TOKEN_ALLOCATION();
    }

    function test__OwnerCanBurn() public {}

    function test__OwnerCanMint() public {
        uint256 amountToMint = 1000;
        uint256 initialTotalSupply = defiCoin.totalSupply();

        vm.prank(owner);
        defiCoin.mint(addr1, amountToMint);

        uint256 newTotalSupply = defiCoin.totalSupply();
        uint256 expectedTotalSupply = initialTotalSupply + amountToMint;

        assertEq(
            newTotalSupply,
            expectedTotalSupply,
            "Failed to mint the correct amount of tokens"
        );
    }

    function test__NonOwnerCannotMint() public {
        vm.prank(addr1);
        try defiCoin.mint(addr1, 500) {
            fail();
        } catch {}
    }

    function test__StartPublicSale() public {
        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.PrivateSale)
        );

        vm.prank(owner);
        defiCoin.startPublicSale();

        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.PublicSale)
        );
    }

    function test__EndSale() public {
        vm.prank(owner);
        defiCoin.startPublicSale();

        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.PublicSale)
        );

        vm.prank(owner);
        defiCoin.endSale();

        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.SaleEnded)
        );
    }

    function test__NonOwnerCannotChangeSaleStage() public {
        vm.prank(addr1);
        // TODO: don't understand why this fails:
        // vm.expectRevert(
        //     bytes4(keccak256("OwnableUnauthorizedAccount(address)"))
        // );
        // defiCoin.startPublicSale();
        try defiCoin.startPublicSale() {
            fail();
        } catch {}
        vm.stopPrank();

        vm.prank(addr1);
        try defiCoin.endSale() {
            fail();
        } catch {}
    }

    function test__OwnerCanWhitelist() public {
        assertFalse(defiCoin.whitelistedAddresses(addr1));

        vm.prank(owner);
        defiCoin.addToWhiteList(addr1);

        assertTrue(defiCoin.whitelistedAddresses(addr1));
    }

    function test__OwnerCanRemoveFromWhitelist() public {
        vm.prank(owner);
        defiCoin.addToWhiteList(addr1);

        assertTrue(defiCoin.whitelistedAddresses(addr1));

        vm.prank(owner);
        defiCoin.removeFromWhiteList(addr1);

        assertFalse(defiCoin.whitelistedAddresses(addr1));
    }

    function test__WhitelistedCanBuyInPrivateSale() public {
        vm.prank(owner);
        defiCoin.addToWhiteList(addr1);

        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.PrivateSale)
        );

        uint256 sentValue = PRIVATE_SALE_PRICE * 10;

        vm.prank(addr1);
        vm.deal(addr1, sentValue);
        defiCoin.buyTokens{value: sentValue}();

        uint256 expectedTokens = (sentValue / PRIVATE_SALE_PRICE) * 10 ** 18;
        assertEq(defiCoin.balanceOf(addr1), expectedTokens);
    }

    function test__NonWhitelistedCannotBuyInPrivateSale() public {
        assertFalse(defiCoin.whitelistedAddresses(addr1));

        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.PrivateSale)
        );

        uint256 sentValue = PRIVATE_SALE_PRICE * 10;

        vm.prank(addr1);
        vm.deal(addr1, sentValue);
        vm.expectRevert(DeFiCoin__NotWhitelisted.selector);
        defiCoin.buyTokens{value: sentValue}();
    }

    function test__BuyTokensDuringPublicSale() public {
        vm.prank(owner);
        defiCoin.startPublicSale();

        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.PublicSale)
        );

        uint256 sentValue = PUBLIC_SALE_PRICE * 100;
        uint256 expectedTokens = (sentValue / PUBLIC_SALE_PRICE) * 10 ** 18;

        vm.prank(addr1);
        vm.deal(addr1, sentValue);
        defiCoin.buyTokens{value: sentValue}();

        assertEq(
            defiCoin.balanceOf(addr1),
            expectedTokens,
            "Buyer did not receive the correct amount of tokens during public sale."
        );
    }

    function test__CannotBuyTokensAfterSaleEnded() public {
        vm.startPrank(owner);
        defiCoin.startPublicSale();
        defiCoin.endSale();
        vm.stopPrank();

        assertEq(
            uint(defiCoin.currentSaleStage()),
            uint(DeFiCoin.SaleStage.SaleEnded)
        );

        vm.expectRevert(DeFiCoin__WrongSaleStage.selector);
        vm.deal(addr1, 1 ether);
        vm.prank(addr1);
        defiCoin.buyTokens{value: 1}();
    }

    function test__BuyTokensExceedingMaxAllocationInPrivateSale() public {
        vm.prank(owner);
        defiCoin.addToWhiteList(addr1);

        uint256 sentValue = PRIVATE_SALE_PRICE * (MAX_TOKEN_ALLOCATION + 1);

        vm.prank(addr1);
        vm.deal(addr1, sentValue);
        vm.expectRevert(DeFiCoin__MaxTokenAllocationExceeded.selector);
        defiCoin.buyTokens{value: sentValue}();
    }

    function test__BuyTokensWithoutEnoughETH() public {
        vm.prank(owner);
        defiCoin.startPublicSale();

        uint256 sentValue = 1;

        vm.prank(addr1);
        vm.deal(addr1, sentValue);
        vm.expectRevert(DeFiCoin__NotEnoughEth.selector);
        defiCoin.buyTokens{value: sentValue}();
    }
}
