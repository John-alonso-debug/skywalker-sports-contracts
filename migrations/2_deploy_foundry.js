const AugurFoundry = artifacts.require('AugurFoundry')

const addresses = require('../scripts/environments/augur-kovan-environment.json')
    .addresses
const contracts = require('../scripts/contracts.json').contracts

const cash = new web3.eth.Contract(
    contracts['Cash.sol'].Cash.abi,
    addresses.Cash
)
const shareToken = new web3.eth.Contract(
    contracts['reporting/ShareToken.sol'].ShareToken.abi,
    addresses.ShareToken
)
//TODO: do this dynamically from contracts
const numTicks = 1000

module.exports = async function (deployer, networks, accounts) {
    await deployer.deploy(
        AugurFoundry,
        addresses.ShareToken,
        addresses.Cash,
        addresses.Augur,
        1000
    )

}

