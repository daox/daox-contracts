pragma solidity ^0.4.11;

import "./DAOLib.sol";
import "./CrowdsaleDAOFields.sol";
import "../Common.sol";
import "./Owned.sol";
import "./DAOProxy.sol";

contract CrowdsaleDAO is CrowdsaleDAOFields, Owned {
    address public stateModule;
    address public paymentModule;
    address public votingDecisionModule;
    address public crowdsaleModule;

    function CrowdsaleDAO(string _name, string _description)
    Owned(msg.sender)
    {
        (name, description) = (_name, _description);
    }

    /*
        State module related functions
    */
    function initState(uint _minVote, address _tokenAddress, address _votingFactory, address _serviceContract) onlyOwner(msg.sender) external {
        DAOProxy.delegatedInitState(stateModule, _minVote, _tokenAddress, _votingFactory, _serviceContract);
    }

    function initHold(uint _tokenHoldTime) onlyOwner(msg.sender) external {
        DAOProxy.delegatedHoldState(stateModule, _tokenHoldTime);
    }

    /*
        Crowdsale module related functions
    */
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) onlyOwner(msg.sender) external {
        DAOProxy.delegatedInitCrowdsaleParameters(crowdsaleModule, _softCap, _hardCap, _rate, _startBlock, _endBlock);
    }

    function() payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, msg.sender, false);
    }

    function handleCommissionPayment(address _sender) payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, _sender, true);
    }

    function finish() onlyOwner(msg.sender) {
        DAOProxy.delegatedFinish(crowdsaleModule);
    }

    /*
        Voting module related functions
    */
    function flushWhiteList() external {
        DAOProxy.delegatedFlushWhiteList(votingDecisionModule);
    }

    function changeWhiteList(address _addr, bool res) external {
        DAOProxy.delegatedChangeWhiteList(votingDecisionModule, _addr, res);
    }

    function withdrawal(address _address, uint withdrawalSum) external {
        DAOProxy.delegatedWithdrawal(votingDecisionModule,_address, withdrawalSum);
    }

    function makeRefundableByUser() external {
        DAOProxy.delegatedMakeRefundableByUser(votingDecisionModule);
    }

    function makeRefundableByVotingDecision() external {
        DAOProxy.delegatedMakeRefundableByUser(votingDecisionModule);
    }

    function holdTokens(address _address, uint duration) external {
        DAOProxy.delegatedHoldTokens(votingDecisionModule, _address, duration);
    }

    /*
        Payment module related functions
    */

    function getCommissionTokens() {
        DAOProxy.delegatedGetCommissionTokens(paymentModule);
    }

    function refund() {
        DAOProxy.delegatedRefund(paymentModule);
    }

    function refundSoftCap()  {
        DAOProxy.delegatedRefundSoftCap(paymentModule);
    }


    /*
        Create proposal functions
    */
    function addProposal(string _description, uint _duration, bytes32[] _options) succeededCrowdsale onlyParticipant {
        DAOLib.delegatedCreateProposal(votingFactory, Common.stringToBytes32(_description), _duration, _options, this);
    }

    function addWithdrawal(string _description, uint _duration, uint _sum) succeededCrowdsale {
        DAOLib.delegatedCreateWithdrawal(votingFactory, Common.stringToBytes32(_description), _duration, _sum, this);
    }

    function addRefund(string _description, uint _duration) succeededCrowdsale {
        DAOLib.delegatedCreateRefund(votingFactory, Common.stringToBytes32(_description), _duration, this);
    }

    function addWhiteList(string _description, uint _duration, address _addr, uint action) succeededCrowdsale {
        DAOLib.delegatedCreateWhiteList(votingFactory, Common.stringToBytes32(_description), _duration, _addr, action, this);
    }

    /*
        Setters for module addresses
    */
    function setStateModule(address _stateModule) external canSetModule(stateModule) notEmptyAddress(_stateModule) {
        stateModule = _stateModule;
    }

    function setPaymentModule(address _paymentModule) external canSetModule(paymentModule) notEmptyAddress(_paymentModule) {
        paymentModule = _paymentModule;
    }

    function setVotingDecisionModule(address _votingDecisionModule) external canSetModule(votingDecisionModule) notEmptyAddress(_votingDecisionModule) {
        votingDecisionModule = _votingDecisionModule;
    }

    function setCrowdsaleModule(address _crowdsaleModule) external canSetModule(crowdsaleModule) notEmptyAddress(_crowdsaleModule) {
        crowdsaleModule = _crowdsaleModule;
    }

    /*
        Self functions
    */
    function isParticipant(address _participantAddress) external constant returns (bool) {
        return participants[_participantAddress];
    }

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusRates) onlyOwner(msg.sender) crowdsaleNotStarted external {
        require(_team.length == tokenPercents.length && _bonusPeriods.length == _bonusRates.length);
        team = _team;
        teamBonusesArr = tokenPercents;
        for(uint i = 0; i < _team.length; i++) {
            teamBonuses[_team[i]] = tokenPercents[i];
        }
        bonusPeriods = _bonusPeriods;
        bonusRates = _bonusRates;
    }

    function setWhiteList(address[] _addresses) onlyOwner(msg.sender) {
        whiteListArr = _addresses;
        for(uint i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = true;
        }
    }

    /*
    Modifiers
    */

    modifier succeededCrowdsale() {
        require(block.number >= endBlock && weiRaised >= softCap);
        _;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }

    modifier crowdsaleNotStarted() {
        require(startBlock == 0 || block.number < startBlock);
        _;
    }

    modifier canSetModule(address module) {
        require(votings[msg.sender] || (module == 0x0 && msg.sender == owner));
        _;
    }

    modifier notEmptyAddress(address _address) {
        require(_address != 0x0);
        _;
    }
}