// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract SVGNFT is ERC721URIStorage {
    uint256 public tokenCounter;

    constructor() ERC721("SVG NFT", "svgNFT") {
        tokenCounter = 0;
    }

    function create(string memory svg) public {
        _safeMint(msg.sender, tokenCounter);
        // imgURI
        // tokenURI
        tokenCounter = tokenCounter + 1;
    }
}
