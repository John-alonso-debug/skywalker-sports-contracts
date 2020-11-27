var Tx = require("ethereumjs-tx");
const Web3 = require("web3");
const provider = new Web3.providers.HttpProvider(
  "https://kovan.infura.io/v3/2a1a54c3aa374385ae4531da66fdf150"
);

const web3 = new Web3(provider);

const { BN, time, constants } = require("@openzeppelin/test-helpers");
const { latest } = require("@openzeppelin/test-helpers/src/time");
const { ZERO_ADDRESS, MAX_UINT256 } = constants;

const privateKey1 = Buffer.from(
  "213b4241c602e46ce57ac851cd72ef5aa1d5b0f1404799099adfc23414b1a3fb",
  "hex"
);

//account related stuff
const accountObj1 = web3.eth.accounts.privateKeyToAccount(
  privateKey1.toString("hex")
);
const account1 = accountObj1.address;

// web3.eth.defaultAccount = account1.address;

//the goal here is to test all the function that will be available to the front end
const contracts = require("./contracts.json").contracts;
const addresses = require("./environments/augur-kovan-environment.json")
  .addresses;

const universe = new web3.eth.Contract(
  contracts["reporting/Universe.sol"].Universe.abi,
  addresses.Universe
);
const augur = new web3.eth.Contract(
  contracts["Augur.sol"].Augur.abi,
  addresses.Augur
);

const erc20 = new web3.eth.Contract(contracts["Cash.sol"].Cash.abi);

const repToken = erc20;
//This is the DAI token
const cash = new web3.eth.Contract(
  contracts["Cash.sol"].Cash.abi,
  addresses.Cash
);
const shareToken = new web3.eth.Contract(
  contracts["reporting/ShareToken.sol"].ShareToken.abi,
  addresses.ShareToken
);
const market = new web3.eth.Contract(
  contracts["reporting/Market.sol"].Market.abi
);
const disputeWindow = new web3.eth.Contract(
  contracts["reporting/DisputeWindow.sol"].DisputeWindow.abi
);
const initialReporter = new web3.eth.Contract(
  contracts["reporting/InitialReporter.sol"].InitialReporter.abi
);

const with18Decimals = function (amount) {
  return amount.mul(new BN(10).pow(new BN(18)));
};
const THOUSAND = with18Decimals(new BN(1000));

//For A YES/No market the outcomes will be three
const OUTCOMES = { INVALID: 0, NO: 1, YES: 2 };
const outComes = [0, 1, 2];
// Object.freeze(outComes);

const sendTx = async function (to, data) {
  console.log("sending Transaction");
  let estimatedGas = await web3.eth.estimateGas({
    from: account1,
    to: to,
    data: data,
  });
  let txCount = await web3.eth.getTransactionCount(account1);

  const txObject = {
    to: to,
    nonce: txCount,
    data: data,
    gas: estimatedGas,
    gasPrice: 1000000000,
  };

  // Sign the transaction
  const tx = new Tx(txObject);
  tx.sign(privateKey1);

  const serializedTx = tx.serialize();
  const raw = "0x" + serializedTx.toString("hex");

  // Broadcast the transaction
  const transaction = await web3.eth.sendSignedTransaction(raw);
  //   console.log(transaction.transactionHash);
  console.log(
    "etherscan link: " +
      "https://kovan.etherscan.io/tx/" +
      transaction.transactionHash
  );
};
const endMarket = async function (marketAddress, winningOutcome) {
  market.options.address = marketAddress;
  let marketReporter = account1;
  //make sure that market is not already finalized

  let isMarketFinalized = await market.methods.isFinalized().call();
  if (isMarketFinalized) {
    console.log("market is already finalized");
    return;
  }
  //make sure that it is time to end the market
  let endTime = new BN(await market.methods.getEndTime().call());
  let currentTime = await getLatestTime();

  if (endTime.gt(currentTime)) {
    console.log(
      "market ends at " +
        endTime.toString() +
        " and time now is " +
        currentTime.toString()
    );
    return;
  }

  //check if intial report is done by whether or not disputeWindow has been deployed
  let disputeWindowAddress = await market.methods.getDisputeWindow().call();
  if (disputeWindowAddress != ZERO_ADDRESS) {
    console.log("initial report is already done");
  } else {
    //check if the reporter address is the same as the designated reporter address
    initialReporter.options.address = await market.methods
      .getInitialReporter()
      .call();
    let desingatedInitialReporter = await initialReporter.methods
      .getDesignatedReporter()
      .call();

    if (desingatedInitialReporter != account1) {
      console.log(
        "initial reporter for this is " +
          desingatedInitialReporter +
          " you are using " +
          account1 +
          " to do the initial report"
      );
    }
    //now we can do the report
    let payouts = [0, 0, 0];
    payouts[winningOutcome] = 1000;

    console.log("doing the initial report");
    let data = market.methods.doInitialReport(payouts, "some", 0).encodeABI();
    await sendTx(market.options.address, data);
    console.log("initial report done");
  }

  //now get the dispute window
  disputeWindow.options.address = await market.methods
    .getDisputeWindow()
    .call();

  let disputeWindowEndTime = new BN(
    await disputeWindow.methods.getEndTime().call()
  );

  if (disputeWindowEndTime.gt(currentTime)) {
    console.log(
      "diputeWindow ends on " +
        disputeWindowEndTime +
        " and time now is " +
        currentTime
    );
    console.log(
      "please wait for " +
        disputeWindowEndTime.sub(currentTime).div(new BN(60)).toString() +
        " minutes and call this function again"
    );
  } else {
    //finalize the market
    let finalizeMarketData = market.methods.finalize().encodeABI();
    sendTx(market.methods.address, finalizeMarketData);
  }
};

endMarket("0x97595679CB0d55230D46E53a07eD3d43764d7A7C", OUTCOMES.NO);

//Make below function availbe in a file as a module
const createYesNoMarket = async function (marketExtraInfo) {
  const repAddress = await universe.methods.getReputationToken().call();
  repToken.options.address = repAddress;
  //not to be used in production
  //start
  if ((await getBalanceOfERC20(repAddress, account1)).isZero()) {
    let data = repToken.methods.faucet(THOUSAND).encodeABI();
    console.log("minting some REP tokens");
    await sendTx(repToken.options.address, data);
  }

  if ((await getBalanceOfERC20(cash.options.address, account1)).isZero()) {
    let data = cash.methods.faucet(THOUSAND).encodeABI();
    console.log("minting some CASH tokens");
    await sendTx(repToken.options.address, data);
  }
  //end

  if (
    new BN(
      await repToken.methods.allowance(account1, augur.options.address).call()
    ).isZero()
  ) {
    console.log("approving REP Tokens to augur");
    let data = await repToken.methods
      .approve(augur.options.address, MAX_UINT256)
      .encodeABI();
    await sendTx(repToken.options.address, data);
  }
  if (
    new BN(
      await repToken.methods.allowance(account1, augur.options.address).call()
    ).isZero()
  ) {
    console.log("approving REP Tokens to augur");
    let data = await repToken.methods
      .approve(augur.options.address, MAX_UINT256)
      .encodeABI();
    await sendTx(repToken.options.address, data);
  }
  let currentTime = await getLatestTime();
  let endTime = currentTime.add(new BN(100));
  let feePerCashInAttoCash = 0;
  let affiliateValidator = ZERO_ADDRESS;
  let affiliateFeeDivisor = 0;
  let designatedReporterAddress = account1;
  // let extraInfo = "none";
  let extraInfo = JSON.stringify(marketExtraInfo);
  console.log("Creating a new YES/NO market");
  let data = universe.methods
    .createYesNoMarket(
      endTime.toString(),
      feePerCashInAttoCash,
      affiliateValidator,
      affiliateFeeDivisor,
      designatedReporterAddress,
      extraInfo
    )
    .encodeABI();
  await sendTx(universe.options.address, data);

  console.log("newly created Market Address: ", await getLatestMarket());
  return await getLatestMarket();
};
// createYesNoMarket("some Extra Info");

const getLatestMarket = async function () {
  let event = await augur.getPastEvents("MarketCreated", {
    fromBlock: "latest",
    toBlock: "latest",
  });
  // console.log("event" + event[0].returnValues.market);
  return event[0].returnValues.market;
};
const getBalanceOfERC20 = async function (tokenAddress, address) {
  erc20.options.address = tokenAddress;
  return new BN(await erc20.methods.balanceOf(address).call());
};
const getLatestTime = async function () {
  let latestBlock = await web3.eth.getBlock("latest");
  return new BN(latestBlock.timestamp);
};
