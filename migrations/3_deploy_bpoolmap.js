const BpoolMaps = artifacts.require('BpoolMaps')



module.exports = async function (deployer, networks, accounts) {
    await deployer.deploy(
        BpoolMaps
    )
}