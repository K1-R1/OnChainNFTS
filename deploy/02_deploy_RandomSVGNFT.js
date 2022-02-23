let { networkConfig } = require('../helper-hardhat-config')

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const { deploy, get, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = await getChainId()

    let linkTokenAddress
    let vrfCoordinatorAddress
    if (chainId == 31337) {
        let linkToken = await get('LinkToken')
        let VRFCoordinatorMock = await get('VRFCoordinatorMock')
        linkTokenAddress = linkToken.address
        vrfCoordinatorAddress = VRFCoordinatorMock.address
    } else {
        linkTokenAddress = networkConfig[chainId]['linkToken']
        vrfCoordinatorAddress = networkConfig[chainId]['vrfCoordinator']
    }
    const keyHash = networkConfig[chainId]['keyHash']
    const fee = networkConfig[chainId]['fee']
    args = [vrfCoordinatorAddress, linkTokenAddress, keyHash, fee]
    log("----------------------------------------------------")
    const RandomSVGNFT = await deploy('RandomSVGNFT', {
        from: deployer,
        args: args,
        log: true
    })
}

module.exports.tags = ['all', 'rsvg']
