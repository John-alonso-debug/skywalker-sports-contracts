## skywalker-sport-contracts

### add .env with private key of the account you want to use in below format

    KOVAN_privateKey = fae42052f82bed612a724fec3632f325f377120592c75bb78adfcceae6470c5a

### All contracts for sports-foundry

-   to Create Market
-   to Mint Share
-   to Wrap Tokens
-   Redeem DAI/USDT

### add .env

-   KOVAN_account=0xAAAAAAAA
-   KOVAN_privateKey=0xBBBBBBBBB
-   MAINNET_account=0xAAAAAAAA
-   MAINNET_privateKey=0xBBBBBBBBB

### install

-   yarn
-   yarn install
-   touch .env
-   edit .env and put privatekey and account
-   truffle migration --network kovan
