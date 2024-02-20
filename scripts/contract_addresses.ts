import Web3 from 'web3'
export const contractAddresses = {
    10: '0x5d470270e889b61c08C51784cDC73442c4554011',
    534352: '0x2bC16Bf30435fd9B3A3E73Eb759176C77c28308D'
}

export const getRewardAddress = async () => {
    const web3 = new Web3(web3Provider)
    const id = await web3.eth.net.getId()
    if (!contractAddresses[id]) throw new Error('Remix reward not deployed on that address')
    console.log('reading', contractAddresses[id])
    return contractAddresses[id]
}