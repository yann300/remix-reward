// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ZKVerifier {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }
}