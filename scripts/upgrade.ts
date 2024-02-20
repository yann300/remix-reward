import { ethers } from "ethers";
import { getRewardAddress } from './contract_addresses'

async function main() {
    const [owner] = await ethers.getSigners();

    const Remix = await ethers.getContractFactory("Remix");    
    const implRemix = await Remix.connect(owner).deploy();
    await implRemix.deployed()

    const implAddress = implRemix.address
    console.log('implementation address', implAddress)

    const proxyAddress = await getRewardAddress()
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
