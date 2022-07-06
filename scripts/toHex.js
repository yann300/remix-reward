import * as multihash from 'multihashes'

const toHex = (ipfsHash) => {
    let buf = multihash.fromB58String(ipfsHash);
    return '0x' + multihash.toHexString(buf);
}
console.log(toHex('QmQU74jFrMXBzioTA9QDxjNbsruEYyiaxxHzjaNzuuvpNq'))