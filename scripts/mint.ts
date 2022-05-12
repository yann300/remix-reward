import * as multihash from 'multihashes'
const ethers = require('ethers');

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
    const address = "0x5d470270e889b61c08C51784cDC73442c4554011" // proxy on Optimism

    const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner()
    const remixV1 = await ethers.getContractFactory("Remix")
    
    let contract = new ethers.Contract(address, remixV1.interface, signer);

    const to = '0xa2Fcc9006eF3C7FfaAcD9fbAf18da98098c0f85b'
    const tokenType = 'Beta Tester'
    const payload = 'v0.22.0'
    const hash = toHex('QmfB5qCsNYukmMmmAZNuUgVkqVjV9QWdTnoun96zohbnbw')
    const mintGrant = 1

    const txSafeMint = await contract.safeMint(to, tokenType, payload, hash, mintGrant)
    const result = await txSafeMint.wait()

    console.log(result)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

