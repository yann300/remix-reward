# Remix Reward

deployed at 0x5d470270e889b61c08C51784cDC73442c4554011 on Optimism

## Overview

Remix reward is a program run by the Remix project. 
It consists of a soulbound nft and is at the moment deployed in the Optimism chain.

Remix Project rewards contributors, beta testers, and UX research participants with NFTs deployed on Optimism.
Remix Reward holders are able to mint a second “Remixer” user NFT badge to any wallet address of their choice.
This feature is a way to reward Remix contributors to help grow our user base into a larger and more genuine open source community of practice.

Remix Rewards are currently not transferable. This feature leaves open the future possibility of granting holders proportional voting power to help the community decide on new features for the IDE and/or other issues governing the development of the Remix toolset.

See the [remix reward website](https://rewards.remix.ethereum.eth.limo) for a list of already minted badges.

## For Challengers

This contract allows users to publish zero knowledge proofs generated using the Remix Challenges program.
The Remix challenges program is run regularly by the Remix project. 
It consists of a list of four questions.
Participants can generate a proof that they found the answer to the four questions without publicly revealing the answers. 
Publishing such a proof to the contract will mint a badge to the participant.

## For Trainers

When a trainer has been whitelisted in the contract (Please join our discord server and the community if you wish to be whitelisted as a trainer),
he/she has the ability to allow student addresses to mint a soulbound nft, within the context of a workshop, classes, etc...

The easiest way for a trainer to allow their students to mint a badge is to run the `grantRemixerMinting.ts` from the `scripts` folder.
Then the student can either: 
    - run the `remixerMint.ts` script.
    - or browse the [remix reward website](https://rewards.remix.ethereum.eth.limo) and go to the section `Mint a badge`

