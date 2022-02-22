const fs = require("fs")
let { networkConfig } = require("../helper-hardhat-config")

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = await getChainId()

    log('\n--------------------')
    const SVGNFT = await deploy("SVGNFT", {
        from: deployer,
        log: true
    })
    log(`SVGNFT contract deployed to ${SVGNFT.address}`)

    let filepath = "./img/circle.svg"
    let svg = fs.readFileSync(filepath, { encoding: "utf8" })

    const SVGNFTContract = await ethers.getContractFactory("SVGNFT")

    const accounts = await hre.ethers.getSigners()
    const signer = accounts[0]

    const svgNFT = new ethers.Contract(SVGNFT.address, SVGNFTContract.interface, signer)

    const networkName = networkConfig[chainId]['name']
    log(`Verify with:\nnpx hardhat verify --network ${networkName} ${svgNFT.address}`)
}