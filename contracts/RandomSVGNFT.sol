// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVGNFT is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;

    // SVG parameters
    uint256 public maxPaths;
    uint256 public maxPathCommands;
    uint256 public size;

    string[] public pathCommands;
    string[] public colours;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event RequestedRandomSVG(
        bytes32 indexed requestId,
        uint256 indexed tokenId
    );
    event CreatedUnfinishedRandomSVG(
        uint256 indexed tokenId,
        uint256 randomNumber
    );
    event CreatedRandomSVGNFT(uint256 indexed tokenId, string tokenURI);

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
        tokenCounter = 0;
        maxPaths = 10;
        maxPathCommands = 5;
        size = 500;
        pathCommands = ["M", "L"];
        colours = [
            "black",
            "blue",
            "red",
            "green",
            "yellow",
            "purple",
            "orange"
        ];
    }

    function create() public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter = tokenCounter + 1;
        emit RequestedRandomSVG(requestId, tokenId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber)
        internal
        override
    {
        address nftOwner = requestIdToSender[_requestId];
        uint256 tokenId = requestIdToTokenId[_requestId];
        _safeMint(nftOwner, tokenId);
        tokenIdToRandomNumber[tokenId] = _randomNumber;
        emit CreatedUnfinishedRandomSVG(tokenId, _randomNumber);
    }

    function finishMint(uint256 _tokenId) public {
        require(
            bytes(tokenURI(_tokenId)).length == 0,
            "tokenURI is already set"
        );
        require(tokenCounter > _tokenId, "tokenId has not yet been minted");
        require(
            tokenIdToRandomNumber[_tokenId] > 0,
            "Random number not yet recieved from VRF"
        );
        uint256 randomNumber = tokenIdToRandomNumber[_tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory _tokenURI = formatTokenURI(imageURI);
        _setTokenURI(_tokenId, _tokenURI);
        emit CreatedRandomSVGNFT(_tokenId, _tokenURI);
    }

    function generateSVG(uint256 _randomNumber)
        public
        view
        returns (string memory finalSVG)
    {
        uint256 numberOfPaths = (_randomNumber % maxPaths) + 2;
        finalSVG = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' height='",
                uint2str(size),
                "' width='",
                uint2str(size),
                "'>"
            )
        );
        for (uint256 i = 0; i < numberOfPaths; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, i)));
            string memory pathSVG = generatePath(newRNG);
            finalSVG = string(abi.encodePacked(finalSVG, pathSVG));
        }
        finalSVG = string(abi.encodePacked(finalSVG, "</svg>"));
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function generatePath(uint256 _randomNumber)
        public
        view
        returns (string memory pathSVG)
    {
        uint256 numberOfPathCommands = (_randomNumber % maxPathCommands) + 2;
        pathSVG = "<path d='";
        //create M command
        uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, size)));
        string memory pathCommand = generatePathCommand(
            newRNG,
            pathCommands[0]
        );
        pathSVG = string(abi.encodePacked(pathSVG, pathCommand));
        //random number of L commands
        for (uint256 i = 0; i < numberOfPathCommands; i++) {
            newRNG = uint256(keccak256(abi.encode(_randomNumber, size + i)));
            pathCommand = generatePathCommand(newRNG, pathCommands[1]);
            pathSVG = string(abi.encodePacked(pathSVG, pathCommand));
        }
        string memory colour = colours[_randomNumber % colours.length];
        pathSVG = string(
            abi.encodePacked(
                pathSVG,
                "' fill='",
                colour,
                "' stroke='",
                colour,
                "'/>"
            )
        );
    }

    function generatePathCommand(uint256 _randomNumber, string memory _command)
        public
        view
        returns (string memory pathCommand)
    {
        uint256 parameterOne = uint256(
            keccak256(abi.encode(_randomNumber, size * 2))
        ) % size;
        uint256 parameterTwo = uint256(
            keccak256(abi.encode(_randomNumber, size * 3))
        ) % size;
        pathCommand = string(
            abi.encodePacked(
                _command,
                uint2str(parameterOne),
                " ",
                uint2str(parameterTwo),
                " "
            )
        );
    }

    function svgToImageURI(string memory _svg)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(_svg)))
        );
        string memory imageURI = string(
            abi.encodePacked(baseURL, svgBase64Encoded)
        );
        return imageURI;
    }

    function formatTokenURI(string memory _imageURI)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "SVG NFT",
                                '", "description":"An NFT based on SVG", "attributes":"", "image":"',
                                _imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
