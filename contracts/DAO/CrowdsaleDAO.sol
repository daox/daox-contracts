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

    function CrowdsaleDAO(string _name, bytes32 _description)
    Owned(msg.sender)
    {
        (name, description) = (_name, _description);
    }

    /*
        State module related functions
    */
    function initState(address _tokenAddress, address _votingFactory, address _serviceContract) external {
        DAOProxy.delegatedInitState(stateModule, _tokenAddress, _votingFactory, _serviceContract);
    }

    function initHold(uint _tokenHoldTime) external {
        DAOProxy.delegatedHoldState(stateModule, _tokenHoldTime);
    }

    /*
        Crowdsale module related functions
    */
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startTime, uint _endTime) external {
        DAOProxy.delegatedInitCrowdsaleParameters(crowdsaleModule, _softCap, _hardCap, _rate, _startTime, _endTime);
    }

    function() payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, msg.sender, false);
    }

    function handleCommissionPayment(address _sender) payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, _sender, true);
    }

    function finish() {
        DAOProxy.delegatedFinish(crowdsaleModule);
    }

    /*
        Voting module related functions
    */
    function withdrawal(address _address, uint withdrawalSum) external {
        DAOProxy.delegatedWithdrawal(votingDecisionModule,_address, withdrawalSum);
    }

    function makeRefundableByUser() external {
        DAOProxy.delegatedMakeRefundableByUser(votingDecisionModule);
    }

    function makeRefundableByVotingDecision() external {
        DAOProxy.delegatedMakeRefundableByVotingDecision(votingDecisionModule);
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
    function addProposal(string _name, string _description, uint _duration, bytes32[] _options) {
        votings[DAOLib.delegatedCreateProposal(votingFactory, _name, _description, _duration, _options, this)] = true;
    }

    function addWithdrawal(string _name, string _description, uint _duration, uint _sum, address withdrawalWallet) {
        votings[DAOLib.delegatedCreateWithdrawal(votingFactory, _name, _description, _duration, _sum, withdrawalWallet, this)] = true;
    }

    function addRefund(string _name, string _description, uint _duration) {
        votings[DAOLib.delegatedCreateRefund(votingFactory, _name, _description, _duration, this)] = true;
    }

    function addModule(string _name, string _description, uint _duration, uint _module, address _newAddress) {
        votings[DAOLib.delegatedCreateModule(votingFactory, _name, _description, _duration, _module, _newAddress, this)] = true;
    }

    /*
        Setters for module addresses
    */
    function setStateModule(address _stateModule) external canSetModule(stateModule) {
        stateModule = _stateModule;
    }

    function setPaymentModule(address _paymentModule) external canSetModule(paymentModule) {
        paymentModule = _paymentModule;
    }

    function setVotingDecisionModule(address _votingDecisionModule) external canSetModule(votingDecisionModule) {
        votingDecisionModule = _votingDecisionModule;
    }

    function setCrowdsaleModule(address _crowdsaleModule) external canSetModule(crowdsaleModule) {
        crowdsaleModule = _crowdsaleModule;
    }

    /*
        Self functions
    */

    function isParticipant(address _participantAddress) external constant returns (bool) {
        return token.balanceOf(_participantAddress) > 0;
    }

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusRates, uint[] _teamHold) onlyOwner(msg.sender) external {
        require(_team.length == tokenPercents.length && _team.length == _teamHold.length && _bonusPeriods.length == _bonusRates.length && canInitBonuses && (block.timestamp < startTime || canInitCrowdsaleParameters));
        team = _team;
        teamHold = _teamHold;
        teamBonusesArr = tokenPercents;
        for(uint i = 0; i < _team.length; i++) {
            teamBonuses[_team[i]] = tokenPercents[i];
        }
        bonusPeriods = _bonusPeriods;
        bonusRates = _bonusRates;

        canInitBonuses = false;
    }

    function setWhiteList(address[] _addresses) onlyOwner(msg.sender) {
        require(canSetWhiteList);

        whiteListArr = _addresses;
        for(uint i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = true;
        }

        canSetWhiteList = false;
    }

    /*
    Modifiers
    */

    modifier canSetModule(address module) {
        require(votings[msg.sender] || (module == 0x0 && msg.sender == owner));
        _;
    }
}