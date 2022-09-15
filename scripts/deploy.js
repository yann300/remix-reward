// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

//import { ethers } from "hardhat";

const { ethers } = require('ethers');
const { expect } = require('chai');

let remix
describe("Basic remix reward deploy", function () {
  it("Deploy", async function () {
    try {
      const [owner, betatester, user] = await ethers.getSigners();
      const Remix = await ethers.getContractFactory("Remix");
      
      remix = await Remix.connect(owner).deploy();
      await remix.deployed();
      console.log("Remix reward deployed to:", remix.address);
      
      expect(await remix.name()).to.equal('Remix');
    } catch (e) {
      console.log(e)
    }
  });

  it("Should mint a badge", async function () {
    try {
      const [owner, betatester, user] = await ethers.getSigners();
      const ipfsHash = '0xabcd1234'
      const txAddType = await remix.addType('Beta Tester')
      await txAddType.wait()
      const mint = await remix.safeMint(betatester.address, 'Beta Tester', '0.22.0', ipfsHash, 2)
      await mint.wait()
      expect((await remix.allowedMinting(betatester.address))).to.equal(2);
      expect((await remix.allowedMinting(user.address))).to.equal(0);
    } catch (e) {
      console.log(e.message)
    }
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

  it("Should not be allowed minting", async function () {
    const [owner, betatester, user] = await ethers.getSigners();
    const ipfsHash = '0xabcd1234'
    await expect(remix.connect(betatester).safeMint(betatester.address, 'Beta Tester', '0.22.0', ipfsHash, 2)).to.be.revertedWith('is missing role 0x0000000000000000000000000000000000000000000000000000000000000000')
  });
});

