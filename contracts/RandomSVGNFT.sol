// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomSVGNFT is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyhash,
        uint256 _fee
    )
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("RandomSVGNFT", "rsNFT")
    {
        keyHash = _keyhash;
        fee = _fee;
    }
}
