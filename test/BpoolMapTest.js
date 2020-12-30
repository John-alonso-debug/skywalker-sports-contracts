const {
    BN,
    constants,
    expectEvent,
    expectRevert,
  } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;
const BpoolMaps = artifacts.require("BpoolMaps");



contract("BpoolMaps", accounts => {
    const fake_market = accounts[3]
const fake_owner =accounts[4]
const fake_pool =accounts[5]
    console.log(`accounts`,accounts)
    it("should get zero_address", () =>
    BpoolMaps.deployed()
        .then(instance => instance.marketsMap.call(fake_market))
        .then(bpool => {
          assert.equal(
            bpool.owner,
            ZERO_ADDRESS,
            "ZERO_ADDRESS wasn't in the first market"
          );
        }));

    

        it("should not call createMap twice by different accounts", async  () => {
           
            let _bpools = await  BpoolMaps.deployed();
            let owner = await _bpools.createMap(fake_market,accounts[5]);
            let _result = await  _bpools.marketsMap(fake_market);
            //console.log(`owner,_result`,owner,_result)
            assert.equal(_result.bpool, fake_pool);
            
            await expectRevert(
                 _bpools.createMap(accounts[3],accounts[5],{from:accounts[2]}),'You are not allow to modify'
            )
          });
    })