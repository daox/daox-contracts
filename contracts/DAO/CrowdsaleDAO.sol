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

    function CrowdsaleDAO(string _name, bytes32 _description) Owned(msg.sender) {
        (name, description) = (_name, _description);
    }

    function() payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, msg.sender, false);
    }

    function handleCommissionPayment(address _sender) payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, _sender, true);
    }

    function handleDXTPayment(address _from, uint _amount) {
        DAOProxy.delegatedHandleDXTPayment(crowdsaleModule, _from, _amount);
    }

    function withdrawal(address _address, uint withdrawalSum, bool dxt) external {
        DAOProxy.delegatedWithdrawal(votingDecisionModule,_address, withdrawalSum, dxt);
    }

    function makeRefundableByVotingDecision() external {
        DAOProxy.delegatedMakeRefundableByVotingDecision(votingDecisionModule);
    }

    function holdTokens(address _address, uint duration) external {
        DAOProxy.delegatedHoldTokens(votingDecisionModule, _address, duration);
    }

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

    function isParticipant(address _participantAddress) external constant returns (bool) {
        return token.balanceOf(_participantAddress) > 0;
    }

    function initState(address _tokenAddress, address _votingFactory, address _serviceContract, address _DXT) public {
        DAOProxy.delegatedInitState(stateModule, _tokenAddress, _votingFactory, _serviceContract, _DXT);
    }

    function initHold(uint _tokenHoldTime) public {
        DAOProxy.delegatedHoldState(stateModule, _tokenHoldTime);
    }

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _DXTRate, uint _startTime, uint _endTime, bool _dxtPayments) public {
        DAOProxy.delegatedInitCrowdsaleParameters(crowdsaleModule, _softCap, _hardCap, _etherRate, _DXTRate, _startTime, _endTime, _dxtPayments);
    }

    function addProposal(string _description, uint _duration, bytes32[] _options) public {
        votings[DAOLib.delegatedCreateProposal(votingFactory, Common.stringToBytes32(_description), _duration, _options, this)] = true;
    }

    function addWithdrawal(string _description, uint _duration, uint _sum, address withdrawalWallet, bool dxt) public {
        votings[DAOLib.delegatedCreateWithdrawal(votingFactory, Common.stringToBytes32(_description), _duration, _sum, withdrawalWallet, dxt, this)] = true;
    }

    function addRefund(string _description, uint _duration) public {
        votings[DAOLib.delegatedCreateRefund(votingFactory, Common.stringToBytes32(_description), _duration, this)] = true;
    }

    function addModule(string _description, uint _duration, uint _module, address _newAddress) public {
        votings[DAOLib.delegatedCreateModule(votingFactory, Common.stringToBytes32(_description), _duration, _module, _newAddress, this)] = true;
    }

    function makeRefundableByUser() public {
        DAOProxy.delegatedMakeRefundableByUser(votingDecisionModule);
    }

    function refund() public {
        DAOProxy.delegatedRefund(paymentModule);
    }

    function refundSoftCap() public {
        DAOProxy.delegatedRefundSoftCap(paymentModule);
    }

    function finish() public {
        DAOProxy.delegatedFinish(crowdsaleModule);
    }

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusEtherRates, uint[] _bonusDXTRates, uint[] _teamHold, bool[] service) public onlyOwner(msg.sender) {
        require(
			_team.length == tokenPercents.length &&
			_team.length == _teamHold.length &&
			_team.length == service.length &&
			_bonusPeriods.length == _bonusEtherRates.length &&
            _bonusPeriods.length == _bonusDXTRates.length &&
			canInitBonuses &&
			(block.timestamp < startTime || canInitCrowdsaleParameters)
        );

        team = _team;
        teamHold = _teamHold;
        teamBonusesArr = tokenPercents;
        teamServiceMember = service;

        for(uint i = 0; i < _team.length; i++) {
            teamBonuses[_team[i]] = tokenPercents[i];
        }

        bonusPeriods = _bonusPeriods;
        bonusEtherRates = _bonusEtherRates;
        bonusDXTRates = _bonusDXTRates;

        canInitBonuses = false;
    }

    function setWhiteList(address[] _addresses) public onlyOwner(msg.sender) {
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