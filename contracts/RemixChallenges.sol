// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./Proof.sol";

contract RemixChallenges is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    
    struct Challenge {
        uint set;
        uint publishersCount;
        address verifier;
        uint challengeHash;
        uint max; 
        string tokenType; 
        string payload; 
        bytes hash;
    }
    uint public challengeIndex;
    mapping  (uint => Challenge) public challenges;

    mapping (bytes => uint) public nullifiers;
    mapping (bytes => uint) public publishers;

    address public rewardContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize() initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setRewardContract (address _reward) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardContract = _reward;
    }

    function setChallenge(Challenge calldata challenge) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        challenges[challengeIndex] = challenge;
        challenges[challengeIndex].publishersCount = 0;
        challenges[challengeIndex].set = 1;
        challengeIndex++;
    }

    function publishChallenge (uint index, ZKVerifier.Proof memory proof, uint[3] memory input) public {
        require(rewardContract != address(0), "rewardontract not set");
        Challenge storage challenge = challenges[index];
        require(challenge.set == 1, "challenge not set");
        require(challenge.verifier != address(0), "no challenge started");
        require(challenge.publishersCount < challenge.max, "publishers reached maximum amount");
        bytes memory nullifier = abi.encodePacked(index, input[2]);
        bytes memory publisher = abi.encodePacked(index, msg.sender);
        require(nullifiers[nullifier] == 0, "proof already published");
        require(publishers[publisher] == 0, "current publisher has already submitted");
        require(challenge.challengeHash == input[1], "provided challenge is not valid");
        
        // function verifyTx(Proof memory proof, uint[3] memory input) public view returns (bool r)
        (bool success, bytes memory data) = challenge.verifier.call{ value: 0 }(
            abi.encodeWithSignature("verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[3])", proof.a, proof.b, proof.c, input)
        );
        
        require(success, "the call to the verifier failed");

        (bool verified) = abi.decode(data, (bool));        
        require(verified, "the provided proof isn't valid");        
        
        challenge.publishersCount++;

        nullifiers[nullifier] = 1;
        publishers[publisher] = 1;

        // function safeMint(address to, string memory tokenType, string memory payload, bytes memory hash, uint mintGrant) public onlyRole(DEFAULT_ADMIN_ROLE)
        (bool successMint, bytes memory dataMint) = rewardContract.call{ value: 0 }(
            abi.encodeWithSignature("safeMint(address,string,string,bytes,uint256)", 
                msg.sender, 
                challenge.tokenType,
                challenge.payload,
                challenge.hash,
                1
            )
        );

        if (!successMint) {
            if (dataMint.length == 0) revert();
            assembly {
                revert(add(32, dataMint), mload(dataMint))
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override   {

    }

    function version () public pure returns (string memory) {
        return "1.0.0";
    }
}