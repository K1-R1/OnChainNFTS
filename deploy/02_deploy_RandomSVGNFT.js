const { ethers } = require('ethers')
let { networkConfig } = require('../helper-hardhat-config')

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const { deploy, get, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = await getChainId()

    // deploy RandomSVGNFT
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
    const networkName = networkConfig[chainId]['name']
    log(`Verify with:\n npx hardhat verify --network ${networkName} ${RandomSVGNFT.address} ${args.toString().replace(/,/g, " ")}`)

    //Fund RandomSVGNFT with LINK
    const linkTokenContract = await ethers.getContractFactory('LinkToken')
    const accounts = await hre.ethers.getSigners()
    const signer = accounts[0]
    const linkToken = new ethers.Contract(linkTokenAddress, linkTokenContract.interface, signer)
    const tx = await linkToken.transfer(RandomSVGNFT.address, fee)
    await tx.wait(1)


}

module.exports.tags = ['all', 'rsvg']
