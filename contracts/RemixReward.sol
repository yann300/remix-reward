// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Remix is ERC721, ERC721Enumerable, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping (string => bool) types;

    mapping (uint => TokenData) tokensData;
    mapping (address => uint) allowedMinting;

    struct TokenData {
        string payload;
        string tokenType;
        string hash;
    }

    constructor() ERC721("Remix", "R") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        types["Educator"] = true;
        types["Release Manager"] = true;
        types["Team Member"] = true;
        types["User"] = true;
        types["Beta Tester"] = true;
        types["Contributor"] = true;
    }

    function addType (string calldata tokenType) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        types[tokenType] = true;
    }

    function removeType (string calldata tokenType) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        delete types[tokenType];
    }

    function safeMint(address to, string calldata tokenType, string calldata payload, string calldata hash, bool grantMinting) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        require(types[tokenType], "type should be declared");
        require(bytes(payload).length != 0, "payload can't be empty");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        tokensData[tokenId].payload = payload;
        tokensData[tokenId].tokenType = tokenType;
        tokensData[tokenId].hash = hash;
        
        if (grantMinting) {
            allowedMinting[to]++;
        }
    }

    function publicMint (address to) public {
        require(allowedMinting[msg.sender] > 0, "no minting allowed");
        allowedMinting[msg.sender]--;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        // tokensData[tokenId].payload = "";
        tokensData[tokenId].tokenType = "User";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        require(from == address(0), "token not transferable");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}