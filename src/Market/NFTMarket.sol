// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.24 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";  
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";  
import "./MyNFT.sol";   
import "./ERC20Token/MyTokenV2.sol";  
import "./ERC20Token/ITokenReceived.sol";

contract NFTMarket is TokenReceived {

    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    IERC20 private paymentToken; // 交易使用的 ERC20 代币
    IERC721 private nftContract; // NFT 合约地址

    // 保存上架的地址和nft
    mapping(uint256 => Listing) private tradeable;

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event TokensReceived(address indexed token,address indexed operator,address indexed from,uint256 value,bytes data);


    constructor(address _paymentToken, address _nftContract) {
        paymentToken = IERC20(_paymentToken);
        nftContract = IERC721(_nftContract);
    }

    function list(uint256 tokenId, uint256 price) public returns (bool) {
        if (msg.sender != IERC721(nftContract).ownerOf(tokenId)) {
            revert("Not owner");
        }
        // 检查是否已经上架
        if (listings[tokenId].active == false) {
            revert("Already listed");
        }
        if (price <= 0) {
            revert("Invalid price");
        }
        // 上架需要先校验是否授权
        if (address(this) != IERC721(nftContract).getApproved(tokenId)) {
            revert("Not authorized");
        }
        // 将NFT上架到商店里，但不转移所有权,只是在交易时需要校验是否是授权状态
        tradeable[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });
        emit NFTListed(tokenId, msg.sender, price);
        return true;
    }

    function buyNFT(uint256 tokenId) public {
        if (msg.sender == IERC721(nftContract).ownerOf(tokenId)) {
            revert("Cannot buy your own NFT");
        }
        if (IERC20(paymentToken).allowance(msg.sender, address(this)) == 0) {
            revert("Not approved");
        }
        if (listings[tokenId].active == false) {
            revert("Not listed");
        }

        _transNFT(nftContract).ownerOf(tokenId), msg.sender, tokenId);

        // 转移代币
        IERC20(paymentToken).transferFrom(msg.sender, IERC721(nftContract).ownerOf(tokenId), tradeable[msg.sender][tokenId]);

        emit NFTBought(tokenId, msg.sender, tradeable[msg.sender][tokenId]);
    }

    function cancelListing(uint256 tokenId) external {
        require(tradeable.seller == msg.sender, "You are not the seller");
        require(tradeable.active, "NFT is not listed");

        delete tradeable[tokenId];
    }

    function tokensReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        if (msg.sender != address(paymentToken)) {
            revert("Only payment token allowed");
        }
        (uint256 tokenId) = abi.decode(data, (uint256));
        if (value != tradeable[tokenId].price) {
            revert("Invalid price");
        }
        emit TokensReceived(msg.sender, operator, from, value, data);
        
        
        _transNFT(tradeable[tokenId].seller, from, tokenId);

        IERC20(paymentToken).transfer(tradeable[tokenId].seller, value);

        return this.tokensReceived.selector;
    }

    function _transNFT(address _from, address _to, uint256 _tokenId) internal {
        IERC721(nftContract).transferFrom(_from, _to, _tokenId);
        // 移除 tradeable 记录
        delete tradeable[tokenId];
    }   
}