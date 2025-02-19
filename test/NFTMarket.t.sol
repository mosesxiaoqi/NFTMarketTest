// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.24 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/Market/NFTMarket.sol";
import {JONASNFT} from "../src/Market/MyNFT.sol";
import {MyToken2} from "../src/Market/ERC20Token/MyTokenV2.sol";


contract NFTMarketTest is Test {
    NFTMarket public market;
    JONASNFT public nft;
    MyToken2 public token;

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTBought(uint256 indexed tokenId, address indexed buyer, uint256 price);

    function setUp() public {
        nft = new JONASNFT();
        token = new MyToken2();
        market = new NFTMarket(address(token), address(nft));
    }

    function test_List() public {
        // 测试上架成功
        address a = makeAddr("first");
        uint256 tokenId_0 = _available(a, 100);

        address b = makeAddr("second");
        uint256 tokenId_1 = nft.mint(b, "test-uri");

        // 测试NFT不是owner上架失败
        _ListTevertTest(b, "Not owner", tokenId_0, 100);

        // 测试重复上架失败
        _ListTevertTest(a, "Already listed", tokenId_0, 100);

        // 测试价格为0失败
        _ListTevertTest(b, "Invalid price", tokenId_1, 0);

        // 测试未授权失败
        _ListTevertTest(b, "Not authorized", tokenId_1, 100);
    }

    function test_buy() public {
        // 测试购买成功
        _test_BuySuccess();

        // 测试购买自己的NFT失败
        _test_BuyOwner();

        // 测试重复购买失败
        _test_RepeatPurchase();

        // 测试未授权失败
        _test_RejectInvalidPayment();

        // 测试购买金额不足失败
        _test_processPaymentMismatch();
    }

    function _test_BuySuccess() public {
        address s = makeAddr("seller1");
        uint256 tokenID = _available(s, 100); //上架
        address b = makeAddr("buyer1");
        _tokenApprove(b, 100, 100);
        vm.expectEmit(true, true, false, false);
        emit NFTBought(tokenID, b, 100);
        _buy(b, tokenID);
        // assertEq(nft.ownerOf(tokenID), b);
    }

    function _test_BuyOwner() public {
        address s = makeAddr("seller2");
        uint256 tokenID = _available(s, 100); //上架
        vm.prank(s);
        token.approve(address(market), 100);
        vm.expectRevert("Cannot buy your own NFT");
        vm.prank(s);
        market.buyNFT(tokenID);
    }

    function _test_RepeatPurchase() public {
        address s = makeAddr("seller3");
        uint256 tokenID = _available(s, 100); //上架
        address b = makeAddr("buyer3");
        _tokenApprove(b, 100, 100);
        _buy(b, tokenID);
        address b1 = makeAddr("buyer4");
        _tokenApprove(b1, 100, 100);
        vm.expectRevert("Not listed");
        _buy(b1, tokenID);
    }

    function _test_RejectInvalidPayment () public {
        address s = makeAddr("seller5");
        uint256 tokenID = _available(s, 100); //上架
        address b = makeAddr("buyer5");
        vm.expectRevert("Not approved");
        vm.prank(b);
        market.buyNFT(tokenID);
    }

    function _test_processPaymentMismatch () public {
        address s = makeAddr("seller6");
        uint256 tokenID = _available(s, 100); //上架
        // address t = makeAddr("tokenowner");


        address b1 = makeAddr("buyer6");
        _tokenApprove(b1, 50, 100);
        vm.expectRevert("Insufficient balance");
        _buy(b1, tokenID);


        address b2 = makeAddr("buyer7");
        _tokenApprove(b2, 150, 50);
        vm.expectRevert("Insufficient allowance");
        _buy(b2, tokenID);
    }

    function _available(address addr, uint256 price) internal returns (uint256) {
        uint256 tokenId_0 = nft.mint(addr, "test-uri");
        _nftApprove(addr, tokenId_0);
        vm.expectEmit(true, true, false, false);
        emit NFTListed(tokenId_0, addr, price);
        vm.prank(addr);
        market.list(tokenId_0, price);
        assertEq(market.getNFTPricing(tokenId_0), price);
        return tokenId_0;
    }

    function _buy(address buyer, uint256 tokenId) internal {
        vm.prank(buyer);   
        market.buyNFT(tokenId);
    }

    function _tokenApprove(address addr, uint256 transfer_amount, uint256 approve_amount) internal {
        token.transfer(addr, transfer_amount);
        vm.prank(addr);
        token.approve(address(market), approve_amount);
    }

    function _nftApprove(address addr, uint256 tokenId) internal {
        vm.prank(addr);
        nft.approve(address(market), tokenId);
    }

    function _ListTevertTest(address addr, string memory str, uint256 tokenId_0, uint256 pice) internal {
        vm.prank(addr);
        vm.expectRevert(bytes(str));
        market.list(tokenId_0, pice);
    }
}