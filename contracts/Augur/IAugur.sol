pragma solidity 0.5.15;

import './libraries/token/IERC20.sol';
import './reporting/IUniverse.sol';
import './reporting/IMarket.sol';
import './reporting/IDisputeWindow.sol';
import './trading/Order.sol';
import './ICash.sol';

contract IAugur {
    IUniverse public genesisUniverse;

    function createChildUniverse(
        bytes32 _parentPayoutDistributionHash,
        uint256[] memory _parentPayoutNumerators
    ) public returns (IUniverse);

    function isKnownUniverse(IUniverse _universe) public view returns (bool);

    function trustedCashTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool);

    function isTrustedSender(address _address) public returns (bool);

    function onCategoricalMarketCreated(
        uint256 _endTime,
        string memory _extraInfo,
        IMarket _market,
        address _marketCreator,
        address _designatedReporter,
        uint256 _feePerCashInAttoCash,
        bytes32[] memory _outcomes
    ) public returns (bool);

    function onYesNoMarketCreated(
        uint256 _endTime,
        string memory _extraInfo,
        IMarket _market,
        address _marketCreator,
        address _designatedReporter,
        uint256 _feePerCashInAttoCash
    ) public returns (bool);

    function onScalarMarketCreated(
        uint256 _endTime,
        string memory _extraInfo,
        IMarket _market,
        address _marketCreator,
        address _designatedReporter,
        uint256 _feePerCashInAttoCash,
        int256[] memory _prices,
        uint256 _numTicks
    ) public returns (bool);

    function logInitialReportSubmitted(
        IUniverse _universe,
        address _reporter,
        address _market,
        address _initialReporter,
        uint256 _amountStaked,
        bool _isDesignatedReporter,
        uint256[] memory _payoutNumerators,
        string memory _description,
        uint256 _nextWindowStartTime,
        uint256 _nextWindowEndTime
    ) public returns (bool);

    function disputeCrowdsourcerCreated(
        IUniverse _universe,
        address _market,
        address _disputeCrowdsourcer,
        uint256[] memory _payoutNumerators,
        uint256 _size,
        uint256 _disputeRound
    ) public returns (bool);

    function logDisputeCrowdsourcerContribution(
        IUniverse _universe,
        address _reporter,
        address _market,
        address _disputeCrowdsourcer,
        uint256 _amountStaked,
        string memory description,
        uint256[] memory _payoutNumerators,
        uint256 _currentStake,
        uint256 _stakeRemaining,
        uint256 _disputeRound
    ) public returns (bool);

    function logDisputeCrowdsourcerCompleted(
        IUniverse _universe,
        address _market,
        address _disputeCrowdsourcer,
        uint256[] memory _payoutNumerators,
        uint256 _nextWindowStartTime,
        uint256 _nextWindowEndTime,
        bool _pacingOn,
        uint256 _totalRepStakedInPayout,
        uint256 _totalRepStakedInMarket,
        uint256 _disputeRound
    ) public returns (bool);

    function logInitialReporterRedeemed(
        IUniverse _universe,
        address _reporter,
        address _market,
        uint256 _amountRedeemed,
        uint256 _repReceived,
        uint256[] memory _payoutNumerators
    ) public returns (bool);

    function logDisputeCrowdsourcerRedeemed(
        IUniverse _universe,
        address _reporter,
        address _market,
        uint256 _amountRedeemed,
        uint256 _repReceived,
        uint256[] memory _payoutNumerators
    ) public returns (bool);

    function logMarketFinalized(
        IUniverse _universe,
        uint256[] memory _winningPayoutNumerators
    ) public returns (bool);

    function logMarketMigrated(IMarket _market, IUniverse _originalUniverse)
        public
        returns (bool);

    function logReportingParticipantDisavowed(
        IUniverse _universe,
        IMarket _market
    ) public returns (bool);

    function logMarketParticipantsDisavowed(IUniverse _universe)
        public
        returns (bool);

    function logCompleteSetsPurchased(
        IUniverse _universe,
        IMarket _market,
        address _account,
        uint256 _numCompleteSets
    ) public returns (bool);

    function logCompleteSetsSold(
        IUniverse _universe,
        IMarket _market,
        address _account,
        uint256 _numCompleteSets,
        uint256 _fees
    ) public returns (bool);

    function logMarketOIChanged(IUniverse _universe, IMarket _market)
        public
        returns (bool);

    function logTradingProceedsClaimed(
        IUniverse _universe,
        address _sender,
        address _market,
        uint256 _outcome,
        uint256 _numShares,
        uint256 _numPayoutTokens,
        uint256 _fees
    ) public returns (bool);

    function logUniverseForked(IMarket _forkingMarket) public returns (bool);

    function logReputationTokensTransferred(
        IUniverse _universe,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fromBalance,
        uint256 _toBalance
    ) public returns (bool);

    function logReputationTokensBurned(
        IUniverse _universe,
        address _target,
        uint256 _amount,
        uint256 _totalSupply,
        uint256 _balance
    ) public returns (bool);

    function logReputationTokensMinted(
        IUniverse _universe,
        address _target,
        uint256 _amount,
        uint256 _totalSupply,
        uint256 _balance
    ) public returns (bool);

    function logShareTokensBalanceChanged(
        address _account,
        IMarket _market,
        uint256 _outcome,
        uint256 _balance
    ) public returns (bool);

    function logDisputeCrowdsourcerTokensTransferred(
        IUniverse _universe,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fromBalance,
        uint256 _toBalance
    ) public returns (bool);

    function logDisputeCrowdsourcerTokensBurned(
        IUniverse _universe,
        address _target,
        uint256 _amount,
        uint256 _totalSupply,
        uint256 _balance
    ) public returns (bool);

    function logDisputeCrowdsourcerTokensMinted(
        IUniverse _universe,
        address _target,
        uint256 _amount,
        uint256 _totalSupply,
        uint256 _balance
    ) public returns (bool);

    function logDisputeWindowCreated(
        IDisputeWindow _disputeWindow,
        uint256 _id,
        bool _initial
    ) public returns (bool);

    function logParticipationTokensRedeemed(
        IUniverse universe,
        address _sender,
        uint256 _attoParticipationTokens,
        uint256 _feePayoutShare
    ) public returns (bool);

    function logTimestampSet(uint256 _newTimestamp) public returns (bool);

    function logInitialReporterTransferred(
        IUniverse _universe,
        IMarket _market,
        address _from,
        address _to
    ) public returns (bool);

    function logMarketTransferred(
        IUniverse _universe,
        address _from,
        address _to
    ) public returns (bool);

    function logParticipationTokensTransferred(
        IUniverse _universe,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fromBalance,
        uint256 _toBalance
    ) public returns (bool);

    function logParticipationTokensBurned(
        IUniverse _universe,
        address _target,
        uint256 _amount,
        uint256 _totalSupply,
        uint256 _balance
    ) public returns (bool);

    function logParticipationTokensMinted(
        IUniverse _universe,
        address _target,
        uint256 _amount,
        uint256 _totalSupply,
        uint256 _balance
    ) public returns (bool);

    function logMarketRepBondTransferred(
        address _universe,
        address _from,
        address _to
    ) public returns (bool);

    function logWarpSyncDataUpdated(
        address _universe,
        uint256 _warpSyncHash,
        uint256 _marketEndTime
    ) public returns (bool);

    function isKnownFeeSender(address _feeSender) public view returns (bool);

    function lookup(bytes32 _key) public view returns (address);

    function getTimestamp() public view returns (uint256);

    function getMaximumMarketEndDate() public returns (uint256);

    function isKnownMarket(IMarket _market) public view returns (bool);

    function derivePayoutDistributionHash(
        uint256[] memory _payoutNumerators,
        uint256 _numTicks,
        uint256 numOutcomes
    ) public view returns (bytes32);

    function logValidityBondChanged(uint256 _validityBond)
        public
        returns (bool);

    function logDesignatedReportStakeChanged(uint256 _designatedReportStake)
        public
        returns (bool);

    function logNoShowBondChanged(uint256 _noShowBond) public returns (bool);

    function logReportingFeeChanged(uint256 _reportingFee)
        public
        returns (bool);

    function getUniverseForkIndex(IUniverse _universe)
        public
        view
        returns (uint256);

    function getMarketType(IMarket _market)
        public
        view
        returns (IMarket.MarketType);

    function getMarketOutcomes(IMarket _market)
        public
        view
        returns (bytes32[] memory _outcomes);

    ICash public cash;
}
