import { ethers } from 'ethers'
import { getRewardAddress } from './contract_addresses'

async function main() {
    try {        
        // proxy on Optimism.
        const address = await getRewardAddress()

        // "signer" represents the current selected account and provider.
        const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner()

        // getContractFactory retruns the compilation result.
        // This will be used in the next line to instantiate an "ethers.Contract" object ot interact with the contract.
        const remixV1 = await ethers.getContractFactory("Remix")
        
        // we finally use the address, the contract interfact and the current context (provider and account)
        // to instantiate an ethers.Contract object.
        let contract = new ethers.Contract(address, remixV1.interface, signer);

        // here is the signature of the function we have to call: "function publicMint (address to) public"
        // it has one parameter "address to". This address is the one that will receive the remixer badge.
        // this can be your own address or any other address:
        const to = ''
               
        const txSafeMint = await contract.publicMint(to)
        
        // this wait for the transaction to be mined.
        const result = await txSafeMint.wait()

        console.log(result)
    } catch (e) {
        console.error(e)
    }    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
});

