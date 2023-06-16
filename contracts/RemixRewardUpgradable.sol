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

import "./Proof.sol";

/**
 * @title Remix Contract
 * @dev A contract for managing the minting, publishing, and challenges of remix tokens.
 */
contract Remix is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Counter for generating token IDs
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Mapping to track supported token types
    mapping(string => bool) types;

    // Mapping to store token data
    mapping(uint => TokenData) public tokensData;

    // Mapping to track minting permissions of addresses
    mapping(address => uint) public allowedMinting;

    // Contributor hash
    bytes public contributorHash;

    // Base URI for token metadata
    string public baseURI;

    // ZKVerifier contract address
    address public zkVerifier;

    // ZKChallenge data
    uint[2] public zkChallenge;
    uint public zkChallengeNonce;
    uint public zkMax;
    uint public publishersAmount;
    mapping(bytes => uint) public nullifiers;
    mapping(bytes => uint) public publishers;

    // Current ZKChallenge token type, payload, and hash
    string public zkChallengeTokenType;
    string public zkChallengePayload;
    bytes public zkChallengeHash;

    // Structure for storing token data
    struct TokenData {
        string payload;
        string tokenType;
        bytes hash;
    }

    /**
     * @dev Initializes the Remix contract.
     */
    function initialize() initializer public {
        __ERC721_init("Remix", "R");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param _uri The base URI to set.
     */
    function setBaseURI(string calldata _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
    }

    /**
     * @dev Retrieves the base URI for token metadata.
     * @return The base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Called by the upgrade mechanism to check if the new implementation should be allowed.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev Adds a new supported token type.
     * @param tokenType The token type to add.
     */
    function addType(string calldata tokenType) public onlyRole(DEFAULT_ADMIN_ROLE) {
        types[tokenType] = true;
    }

    /**
     * @dev Removes a supported token type.
     * @param tokenType The token type to remove.
     */
    function removeType(string calldata tokenType) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete types[tokenType];
    }

    /**
     * @dev Sets the contributor hash.
     * @param hash The contributor hash to set.
     */
    function setContributorHash(bytes calldata hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contributorHash = hash;
    }

    /**
     * @dev Mints a new token.
     * @param to The address to mint the token to.
     * @param tokenType The token type.
     * @param payload The token payload.
     * @param hash The token hash.
     * @param mintGrant The minting permission granted to the recipient.
     */
    function safeMint(address to, string memory tokenType, string memory payload, bytes memory hash, uint mintGrant) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintBadge(to, tokenType, payload, hash, mintGrant);
    }

    /**
     * @dev Internal function to mint a badge token.
     * @param to The address to mint the token to.
     * @param tokenType The token type.
     * @param payload The token payload.
     * @param hash The token hash.
     * @param mintGrant The minting permission granted to the recipient.
     */
    function mintBadge(address to, string memory tokenType, string memory payload, bytes memory hash, uint mintGrant) private {
        require(types[tokenType], "type should be declared");
        
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

    /**
     * @dev Assigns a hash to a token.
     * @param tokenId The ID of the token.
     * @param hash The hash to assign.
     */
    function assignHash(uint tokenId, bytes calldata hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _requireMinted(tokenId);
        require(tokensData[tokenId].hash.length == 0, "hash already set");
        tokensData[tokenId].hash = hash;
    }

    /**
     * @dev Mints a token for the caller.
     */
    function publicMint() public {
        require(allowedMinting[msg.sender] > 0, "no minting allowed");
        allowedMinting[msg.sender]--;
        mintRemixer(msg.sender);
    }

    /**
     * @dev Internal function to mint a remixer token.
     * @param to The address to mint the token to.
     */
    function mintRemixer(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        tokensData[tokenId].tokenType = "Remixer";
        tokensData[tokenId].hash = contributorHash;
    }

    /**
     * @dev Grants minting permissions to a list of remixers.
     * @param remixers The addresses to grant minting permissions to.
     * @param amount The amount of minting permissions to grant.
     */
    function grantRemixersMinting(address[] calldata remixers, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint k = 0; k < remixers.length; k++) {
            allowedMinting[remixers[k]] += amount;
        }
    }

    /**
     * @dev Revokes minting permissions from a list of remixers.
     * @param remixers The addresses to revoke minting permissions from.
     * @param amount The amount of minting permissions to revoke.
     */
    function revokeRemixersMinting(address[] calldata remixers, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint k = 0; k < remixers.length; k++) {
            require(allowedMinting[remixers[k]] >= amount, "not enough minting permissions");
            allowedMinting[remixers[k]] -= amount;
        }
    }

    /**
     * @dev Creates a new challenge by setting the ZKChallenge data.
     * @param challengeTokenType The token type of the challenge.
     * @param challengePayload The payload of the challenge.
     * @param challengeHash The hash of the challenge.
     * @param max The maximum number of tokens to be published as a solution.
     * @param publishersList The addresses of the publishers allowed to publish solutions.
     */
    function createChallenge(string calldata challengeTokenType, string calldata challengePayload, bytes calldata challengeHash, uint max, address[] calldata publishersList) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(types[challengeTokenType], "challenge type should be declared");
        require(publishersList.length > 0, "publishers list should not be empty");

        zkChallengeTokenType = challengeTokenType;
        zkChallengePayload = challengePayload;
        zkChallengeHash = challengeHash;
        zkChallengeNonce++;
        zkMax = max;
        publishersAmount = publishersList.length;

        for (uint k = 0; k < publishersList.length; k++) {
            publishers[abi.encodePacked(challengeTokenType, challengePayload, challengeHash, k)] = k;
        }
    }

    /**
     * @dev Publishes a solution to a challenge.
     * @param solutionType The token type of the solution.
     * @param solutionPayload The payload of the solution.
     * @param proof The proof data of the solution.
     */
    function publishChallenge(string calldata solutionType, string calldata solutionPayload, uint[2] calldata proof) public {
        require(types[solutionType], "solution type should be declared");
        require(publishers[abi.encodePacked(zkChallengeTokenType, zkChallengePayload, zkChallengeHash, proof[0])] > 0, "not a valid publisher");
        require(proof[1] < zkMax, "exceeded maximum solutions");

        bytes memory solutionHash = Proof.hash(solutionType, solutionPayload, proof);
        require(solutionHash.length > 0, "invalid solution hash");
        require(nullifiers[solutionHash] == 0, "solution already published");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        tokensData[tokenId].tokenType = solutionType;
        tokensData[tokenId].payload = solutionPayload;
        tokensData[tokenId].hash = solutionHash;
        nullifiers[solutionHash] = tokenId;
    }
}
