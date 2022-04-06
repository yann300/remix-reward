// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

//import { ethers } from "hardhat";

const ethers = require('ethers');
const { expect } = require('chai');

let remix
describe("Basic remix reward deploy", function () {
  this.timeout(10000)
  it("Deploy", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    const Remix = await ethers.getContractFactory("Remix");
    
    remix = await Remix.connect(owner).deploy();
    await remix.deployed();
    console.log("Remix reward deployed to:", remix.address);
    
    expect(await remix.name()).to.equal('Remix');
  });

  it("Should mint a badge", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    const ipfsHash = '0xabcd1234'
    const mint = await remix.safeMint(betatester.address, 'Beta Tester', '0.22.0', ipfsHash, 2)
    await mint.wait()
    expect((await remix.allowedMinting(betatester.address))).to.equal(2);
    expect((await remix.allowedMinting(user.address))).to.equal(0);
  });

  it("Should re-mint a badge", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    const ipfsHash = '0xabcd1244'
    const mint = await remix.connect(betatester).publicMint(user.address)
    await mint.wait()
    expect((await remix.allowedMinting(betatester.address))).to.equal(1);

    expect((await remix.allowedMinting(user.address))).to.equal(0);
    expect((await remix.balanceOf(user.address))).to.equal(1);
  });

  it("Should not allowed minting", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    const ipfsHash = '0xabcd1234'
    // const tx = await remix.connect(betatester).safeMint(betatester.address, 'Beta Tester', '0.22.0', ipfsHash, 2)
    // await tx.wait()
    await expect(remix.connect(betatester).safeMint(betatester.address, 'Beta Tester', '0.22.0', ipfsHash, 2)).to.be.revertedWith('caller is not the owner')
  });
});

