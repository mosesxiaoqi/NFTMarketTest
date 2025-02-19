// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.24 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract JONASNFT is ERC721 {

    uint256 private _tokenId;
    mapping(uint256 tokenId => string) private _tokenURIs;

    event MetadataSet(uint256 tokenId, string _tokenURI);

    constructor() ERC721("JONASNFT", "JONAS") {
        _tokenId = 0;
    }

    function mint(address to, string memory _tokenURI) public {
        _safeMint(to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _tokenId++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataSet(tokenId, _tokenURI);
    }   
}
