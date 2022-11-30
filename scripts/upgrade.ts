import { ethers } from "ethers";

async function main() {
    const [owner] = await ethers.getSigners();

    const Remix = await ethers.getContractFactory("Remix");    
    const implRemix = await Remix.connect(owner).deploy();
    await implRemix.deployed()

    const implAddress = implRemix.address
    console.log('implementation address', implAddress)

    const proxyAddress = '0xf8e81D47203A594245E36C48e151709F0C19fBe8'
    const remix = await ethers.getContractAt("Remix", proxyAddress)
    const updated = await remix.connect(owner).upgradeTo(implAddress)
    updated.wait()
    console.log('updated')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
});
