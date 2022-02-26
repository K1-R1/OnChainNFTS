let { networkConfig } = require('../helper-hardhat-config')
const fs = require('fs')

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {

    //Deploy RandomSVGNFT
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
        additionalMessage = " --linkaddress " + linkTokenAddress
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
    const RandomSVGNFTContract = await ethers.getContractFactory("RandomSVGNFT")
    const accounts = await hre.ethers.getSigners()
    const signer = accounts[0]
    const randomSVGNFT = new ethers.Contract(RandomSVGNFT.address, RandomSVGNFTContract.interface, signer)

    //Fund with LINK
    const linkTokenContract = await ethers.getContractFactory("LinkToken")
    const linkToken = new ethers.Contract(linkTokenAddress, linkTokenContract.interface, signer)
    let fund_tx = await linkToken.transfer(RandomSVGNFT.address, fee)
    await fund_tx.wait(1)

    //Mint NFT
    tx = await randomSVGNFT.create({ gasLimit: 300000 })
    let receipt = await tx.wait(1)
    let tokenId = receipt.events[3].topics[2]
    log(`NFT minted with ID: ${tokenId}`)
    if (chainId != 31337) {
        await new Promise(r => setTimeout(r, 180000))
        tx = await randomSVGNFT.finishMint(tokenId, { gasLimit: 5000000 })
        await tx.wait(1)
        log(`You can view the tokenURI at: ${await randomSVGNFT.tokenURI(tokenId)}`)
    } else {
        const VRFCoordinatorMock = await deployments.get('VRFCoordinatorMock')
        vrfCoordinator = await ethers.getContractAt('VRFCoordinatorMock', VRFCoordinatorMock.address, signer)
        let transactionResponse = await vrfCoordinator.callBackWithRandomness(receipt.logs[3].topics[1], 77777, randomSVGNFT.address)
        await transactionResponse.wait(1)
        tx = await randomSVGNFT.finishMint(tokenId, { gasLimit: 2000000 })
        await tx.wait(1)
        log(`You can view the tokenURI at: ${await randomSVGNFT.tokenURI(0)}`)
    }
}

module.exports.tags = ['all', 'rsvg']