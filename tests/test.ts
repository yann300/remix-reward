// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

import { ethers } from "ethers";
import { expect } from "chai";
import { proofs } from "./data"
import { toHex } from 'web3-utils'

let remix: ethers.Contract
let proxy: ethers.Contract
let verifier: ethers.Contract
describe("Basic remix reward deploy", function () {
  it("Deploy with proxy", async function () {
    const [owner, betatester, user] = await ethers.getSigners();

    const Remix = await ethers.getContractFactory("Remix");    
    remix = await Remix.connect(owner).deploy();
    await remix.deployed()

    const implAddress = remix.address
    console.log('implementation address', implAddress)

    const Proxy = await ethers.getContractFactory('ERC1967Proxy')
    proxy = await Proxy.connect(owner).deploy(implAddress, '0x8129fc1c')
    await proxy.deployed()
    console.log("Remix reward deployed to:", proxy.address);

    remix = await ethers.getContractAt("Remix", proxy.address)
    remix = remix.connect(owner)

    expect(await remix.name()).to.equal('Remix');
  });

  it("Should mint a badge", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    const ipfsHash = '0xabcd1234'
    const txAddType = await remix.addType('Beta Tester')
    await txAddType.wait()
    const mint = await remix.safeMint(betatester.address, 'Beta Tester', '0.22.0', ipfsHash, 2)
    await mint.wait()
    expect((await remix.allowedMinting(betatester.address))).to.equal(2);
    expect((await remix.allowedMinting(user.address))).to.equal(0);
  });

  it("Should re-mint a badge", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    
    const mint = await remix.connect(betatester).publicMint(user.address)
    await mint.wait()
    expect((await remix.allowedMinting(betatester.address))).to.equal(1);

    expect((await remix.allowedMinting(user.address))).to.equal(0);
    expect((await remix.balanceOf(user.address))).to.equal(1);

  });

  it("Should assign an empty hash", async function () {
    const [owner, betatester, user] = await ethers.getSigners();

    // check if hash is empty
    let data = await remix.tokensData(1)
    expect(data[2]).to.equal('0x');
    
    // assign it
    await (await remix.connect(owner).assignHash(1, '0xabcd'))
    data = await remix.tokensData(1)
    expect(data[2]).to.equal('0xabcd');

    // should not allow re-assigning an hash
    await expect(remix.connect(owner).assignHash(1, '0xabef')).to.be.revertedWith('revert hash already set')
  });

  it("Set a contributor badge hash", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    await expect(remix.connect(betatester).setContributorHash('0x000000000000000000000000000000000000000000000000000000000000000a'))
      .to.be.revertedWith('is missing role 0x0000000000000000000000000000000000000000000000000000000000000000') // remixer badge hash
    const contributor = await remix.connect(owner).setContributorHash('0x000000000000000000000000000000000000000000000000000000000000000a')
    await contributor.wait()
  });

  it("Should not be allowed minting", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    const ipfsHash = '0xabcd1234'
    await expect(remix.connect(betatester).safeMint(betatester.address, 'Beta Tester', '0.22.0', ipfsHash, 2)).to.be.revertedWith('is missing role 0x0000000000000000000000000000000000000000000000000000000000000000')
  });

  it("Should publish verifier", async function () {
    const [owner, betatester, user, betatester2] = await ethers.getSigners();
    // deploy verifier
    const Verifier = await ethers.getContractFactory("Groth16Verifier");      
    verifier = await Verifier.connect(owner).deploy();
    await verifier.deployed();    
  });

  const challengeHashes = ['10805175833937845557201839769804057382368594205392463841800803916892395711484']
  const tokenType = 'remix challenge'
  const payload = 'no payload'
  const hash =  '0xabababcdef12'

  it("Should set a new challenge", async function () {
    const [owner, betatester, user, betatester2] = await ethers.getSigners();
    
    console.log("verifier address", verifier.address)
    const setChallengeTx = await remix.connect(owner).setChallenge(verifier.address, challengeHashes, 3, tokenType, payload, hash);
    await setChallengeTx.wait()
  })

  it("Should refuse an invalid challenge", async function () {   
    const [owner, betatester, user, betatester2] = await ethers.getSigners();

    let proofStruct = {
            a: proofs.proof1[0],
            b: proofs.proof1[1],
            c: proofs.proof1[2],
        }
    proofStruct.a = [
            "0x11b3ef927dfb8c935901ccbcc2b8e7c57049e1bb3eafff67cd4dd44950759f17",
            "0x1c79b1dd1e858f524854357a191cdf40716297fffb8c5503edd0d5801ab86e9d"
        ]
    await expect(remix.connect(betatester2).publishChallenge(proofStruct, proofs.proof1[3])).to.be.revertedWith("the provided proof isn't valid")
  });

  it("Should accept a challenge", async function () {   
    const [owner, betatester, user, betatester2] = await ethers.getSigners();

     let proofStruct = {
            a: proofs.proof1[0],
            b: proofs.proof1[1],
            c: proofs.proof1[2],
        }
    const publishChallengeTx = await remix.connect(betatester2).publishChallenge(proofStruct, proofs.proof1[3])
    await publishChallengeTx.wait()
    const balance = await remix.connect(betatester2).balanceOf(betatester2.address)
    const tokenId = await remix.connect(betatester2).tokenOfOwnerByIndex(betatester2.address, balance - 1)
    const tokenData = await remix.connect(betatester2).tokensData(tokenId)    
    expect(tokenData.payload).to.be.equal(payload)
    expect(tokenData.tokenType).to.be.equal(tokenType)
    expect(tokenData.hash).to.be.equal(hash)
  });

  it("Should refuse a challenge if proof has already been published", async function () {    
    const [owner, betatester, user, betatester2] = await ethers.getSigners();
    let proofStruct = {
            a: proofs.proof1[0],
            b: proofs.proof1[1],
            c: proofs.proof1[2],
        }
    await expect(remix.connect(owner).publishChallenge(proofStruct, proofs.proof1[3])).to.be.revertedWith('proof already published')
  });

  it("Should refuse a challenge if sender already published a valid solution", async function () {    
    const [owner, betatester, user, betatester2] = await ethers.getSigners();
    
    let proofStruct = {
            a: proofs.proof2[0],
            b: proofs.proof2[1],
            c: proofs.proof2[2],
        }
    await expect(remix.connect(betatester2).publishChallenge(proofStruct, proofs.proof2[3])).to.be.revertedWith('current publisher has already submitted')
  });

  it("Published should reach maximum count", async function () {    
    const [owner, betatester, user, betatester2, user2, user3] = await ethers.getSigners();
    
    let proofStruct = {
            a: proofs.proof2[0],
            b: proofs.proof2[1],
            c: proofs.proof2[2],
        }
    const pub2 = await remix.connect(owner).publishChallenge(proofStruct, proofs.proof2[3])
    await pub2.wait()

    proofStruct = {
            a: proofs.proof3[0],
            b: proofs.proof3[1],
            c: proofs.proof3[2],
        }
    const pub3 = await remix.connect(user2).publishChallenge(proofStruct, proofs.proof3[3])
    await pub3.wait()

    expect(await remix.publishersAmount()).to.be.equal(3)

    proofStruct = {
            a: proofs.proof4[0],
            b: proofs.proof4[1],
            c: proofs.proof4[2],
        }
    expect(remix.connect(user3).publishChallenge(proofStruct, proofs.proof4[3])).to.revertedWith('publishers reached maximum amount')
  });

  it("Should re-set a new challenge", async function () {
    const [owner, betatester, user, betatester2] = await ethers.getSigners();
    
    console.log("verifier address", verifier.address)
    const setChallengeTx = await remix.connect(owner).setChallenge(verifier.address, challengeHashes, 3, tokenType, payload, hash);
    await setChallengeTx.wait()
  })

  it("Should refuse again an invalid challenge", async function () {   
    const [owner, betatester, user, betatester2] = await ethers.getSigners();

    const proofStruct = {
            a: proofs.proof1[0],
            b: proofs.proof1[1],
            c: proofs.proof1[2],
        }
  
    const invalidSignals = [
      proofs.proof1[3][0],
      proofs.proof1[3][1],
      "0x00000000000000000000000000000000d421714eddc84195ee8f80d5379cf6fa", // invalid
    ]
    await expect(remix.connect(betatester2).publishChallenge(proofStruct, invalidSignals)).to.be.revertedWith("the provided proof isn't valid")
  });

  it("Should accept again a challenge", async function () {   
    const [owner, betatester, user, betatester2] = await ethers.getSigners();

    const proofStruct = {
            a: proofs.proof1[0],
            b: proofs.proof1[1],
            c: proofs.proof1[2],
        }
    const publishChallengeTx = await remix.connect(betatester2).publishChallenge(proofStruct, proofs.proof1[3])
    await publishChallengeTx.wait()
  });
});

