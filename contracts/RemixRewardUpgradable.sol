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
 * @custom:dev-run-script ./scripts/deploy.js
 */
contract Remix is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping (string => bool) types;
    mapping (uint => TokenData) public tokensData;
    mapping (address => uint) public allowedMinting;
    bytes public contributorHash;
    string public baseURI;
    
    address public zkVerifier;
    uint[2] public zkChallenge; // only the first item is used.
    uint public zkChallengeNonce;
    uint public zkMax;
    uint public publishersAmount;
    mapping (bytes => uint) public nullifiers;
    mapping (bytes => uint) public publishers;

    string public zkChallengeTokenType;
    string public zkChallengePayload;
    bytes public zkChallengeHash;

    mapping(address => uint) public trainers;

    struct TokenData {
        string payload;
        string tokenType;
        bytes hash;
    }

    modifier isTrainer() {
        require(trainers[msg.sender] == 1, "Caller is not a trainer");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize() initializer public {
        __ERC721_init("Remix", "R");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setBaseURI (string calldata _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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

    function setContributorHash(bytes calldata hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contributorHash = hash;
    }

    function safeMint(address to, string memory tokenType, string memory payload, bytes memory hash, uint mintGrant) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintBadge(to, tokenType, payload, hash, mintGrant);
    }

    function mintBadge(address to, string memory tokenType, string memory payload, bytes memory hash, uint mintGrant) private {
        require(types[tokenType], "type should be declared");
        // require(bytes(payload).length != 0, "payload can't be empty");
        
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

    function assignHash(uint tokenId, bytes calldata hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _requireMinted(tokenId);
        require(tokensData[tokenId].hash.length == 0, "hash already set");
        tokensData[tokenId].hash = hash;
    }

    function publicMint (address to) public {
        require(allowedMinting[msg.sender] > 0, "no minting allowed");
        allowedMinting[msg.sender]--;
        mintRemixer(to);
    }

    function mintRemixer(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        // tokensData[tokenId].payload = "";
        tokensData[tokenId].tokenType = "Remixer";
        tokensData[tokenId].hash = contributorHash;
    }

    function addTrainer (address trainer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        trainers[trainer] = 1;
    }

    function removeTrainer (address trainer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete trainers[trainer];
    }

    function grantRemixersMinting (address[] calldata remixers, uint amount) public isTrainer()  {
        for (uint k = 0; k < remixers.length; k++) {
            allowedMinting[remixers[k]] += amount;
        }
    }

    function setChallenge(address verifier, uint[1] calldata challenge, uint max, string calldata tokenType, string calldata payload, bytes calldata hash) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        addType(tokenType);
        zkVerifier = verifier;
        zkChallenge = challenge;
        zkChallengeTokenType = tokenType;
        zkChallengePayload = payload;
        zkChallengeHash = hash;
        zkMax = max;
        publishersAmount = 0;
        zkChallengeNonce++;
    }

    function publishChallenge (ZKVerifier.Proof memory proof, uint[3] memory input) public {
        require(zkVerifier != address(0), "no challenge started");
        require(publishersAmount < zkMax, "publishers reached maximum amount");
        bytes memory nullifier = abi.encodePacked(zkChallengeNonce, input[2]);
        bytes memory publisher = abi.encodePacked(zkChallengeNonce, msg.sender);
        require(nullifiers[nullifier] == 0, "proof already published");
        require(publishers[publisher] == 0, "current publisher has already submitted");
        require(zkChallenge[0] == input[1], "provided challenge is not valid");
        
        // function verifyTx(Proof memory proof, uint[3] memory input) public view returns (bool r)
        (bool success, bytes memory data) = zkVerifier.call{ value: 0 }(
            abi.encodeWithSignature("verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[3])", proof.a, proof.b, proof.c, input)
        );
        
        require(success, "the call to the verifier failed");

        (bool verified) = abi.decode(data, (bool));        
        require(verified, "the provided proof isn't valid");        
        
        mintBadge(msg.sender, zkChallengeTokenType, zkChallengePayload, zkChallengeHash, 1);
        publishersAmount++;

        nullifiers[nullifier] = 1;
        publishers[publisher] = 1;        
    }

    function version () public pure returns (string memory) {
        return "2.6.0";
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
