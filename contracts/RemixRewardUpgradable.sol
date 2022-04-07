// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Remix is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping (string => bool) types;
    mapping (uint => TokenData) tokensData;
    mapping (address => uint) public allowedMinting;

    struct TokenData {
        string payload;
        string tokenType;
        bytes hash;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        initialize();
    }

    function initialize() initializer public {
        __ERC721_init("Remix", "R");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // intialize default values
        types["Educator"] = true;
        types["Release Manager"] = true;
        types["Team Member"] = true;
        types["User"] = true;
        types["Beta Tester"] = true;
        types["Contributor"] = true;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        override
    {}

    function addType (string calldata tokenType) public onlyRole(DEFAULT_ADMIN_ROLE) {
        types[tokenType] = true;
    }

    function removeType (string calldata tokenType) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete types[tokenType];
    }

    function safeMint(address to, string calldata tokenType, string calldata payload, bytes calldata hash, uint mintGrant) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(types[tokenType], "type should be declared");
        require(bytes(payload).length != 0, "payload can't be empty");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        tokensData[tokenId].payload = payload;
        tokensData[tokenId].tokenType = tokenType;
        tokensData[tokenId].hash = hash;
        
        if (mintGrant > 0) {
            allowedMinting[to] = allowedMinting[to] + mintGrant;
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
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        require(from == address(0), "token not transferable");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
