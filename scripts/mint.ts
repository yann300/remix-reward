import * as multihash from 'multihashes'
import { ethers } from 'ethers'

const toHex = (ipfsHash) => {
    let buf = multihash.fromB58String(ipfsHash);
    return '0x' + multihash.toHexString(buf);
}

const toBase58 = (contentHash) => {
    let hex = contentHash.substring(2)
    let buf = multihash.fromHexString(hex);
    return multihash.toB58String(buf);
}

async function main() {
    try {        
        const address = "0x5d470270e889b61c08C51784cDC73442c4554011" // proxy on Optimism

        const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner()
        const remixV1 = await ethers.getContractFactory("Remix")
        
        let contract = new ethers.Contract(address, remixV1.interface, signer);

        const to = ''
        const tokenType = 'Beta Tester'
        const payload = 'v0.24.0'
        const hash = toHex('QmSg1zpxPcgCryNok8J9KRHa7jouuj99nxZPcc7t7MnoMY')
        const mintGrant = 1
        
        const txSafeMint = await contract.safeMint(to, tokenType, payload, hash, mintGrant)
        
        const result = await txSafeMint.wait()

        console.log(result)
    } catch (e) {
        console.error(e)
    }    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    // process.exitCode = 1;
});

