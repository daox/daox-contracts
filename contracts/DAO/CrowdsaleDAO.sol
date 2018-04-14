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

    function CrowdsaleDAO(string _name, string _description, address _serviceContractAddress, address _votingFactoryContractAddress)
    Owned(msg.sender) {
        (name, description, serviceContract, votingFactory) = (_name, _description, _serviceContractAddress, VotingFactoryInterface(_votingFactoryContractAddress));
    }

    function() payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, msg.sender, false);
    }

    function handleCommissionPayment(address _sender) payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, _sender, true);
    }

    function handleDXCPayment(address _from, uint _amount) {
        DAOProxy.delegatedHandleDXCPayment(crowdsaleModule, _from, _amount);
    }

    function withdrawal(address _address, uint withdrawalSum, bool dxc) external {
        DAOProxy.delegatedWithdrawal(votingDecisionModule,_address, withdrawalSum, dxc);
    }

    function makeRefundableByVotingDecision() external {
        DAOProxy.delegatedMakeRefundableByVotingDecision(votingDecisionModule);
    }

    function holdTokens(address _address, uint duration) external {
        DAOProxy.delegatedHoldTokens(votingDecisionModule, _address, duration);
    }

    function setStateModule(address _stateModule) external canSetAddress(stateModule) {
        stateModule = _stateModule;
    }

    function setPaymentModule(address _paymentModule) external canSetAddress(paymentModule) {
        paymentModule = _paymentModule;
    }

    function setVotingDecisionModule(address _votingDecisionModule) external canSetAddress(votingDecisionModule) {
        votingDecisionModule = _votingDecisionModule;
    }

    function setCrowdsaleModule(address _crowdsaleModule) external canSetAddress(crowdsaleModule) {
        crowdsaleModule = _crowdsaleModule;
    }

    function setVotingFactoryAddress(address _votingFactory) external canSetAddress(votingFactory) {
        votingFactory = VotingFactoryInterface(_votingFactory);
    }

    function isParticipant(address _participantAddress) external constant returns (bool) {
        return token.balanceOf(_participantAddress) > 0;
    }

    function initState(address _tokenAddress, address _DXC) public {
        DAOProxy.delegatedInitState(stateModule, _tokenAddress, _DXC);
    }

    function initHold(uint _tokenHoldTime) public {
        DAOProxy.delegatedHoldState(stateModule, _tokenHoldTime);
    }

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _DXCRate, uint _startTime, uint _endTime, bool _dxcPayments) public {
        DAOProxy.delegatedInitCrowdsaleParameters(crowdsaleModule, _softCap, _hardCap, _etherRate, _DXCRate, _startTime, _endTime, _dxcPayments);
    }

    function addProposal(string _name, string _description, uint _duration, bytes32[] _options) public {
        votings[DAOLib.delegatedCreateProposal(votingFactory, _name, _description, _duration, _options, this)] = true;
    }

    function addWithdrawal(string _name, string _description, uint _duration, uint _sum, address withdrawalWallet, bool dxc) public {
        votings[DAOLib.delegatedCreateWithdrawal(votingFactory, _name, _description, _duration, _sum, withdrawalWallet, dxc, this)] = true;
    }

    function addRefund(string _name, string _description, uint _duration) public {
        votings[DAOLib.delegatedCreateRefund(votingFactory, _name, _description, _duration, this)] = true;
    }

    function addModule(string _name, string _description, uint _duration, uint _module, address _newAddress) public {
        votings[DAOLib.delegatedCreateModule(votingFactory, _name, _description, _duration, _module, _newAddress, this)] = true;
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

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusEtherRates, uint[] _bonusDXCRates, uint[] _teamHold, bool[] service) public onlyOwner(msg.sender) {
        require(
            _team.length == tokenPercents.length &&
            _team.length == _teamHold.length &&
            _team.length == service.length &&
            _bonusPeriods.length == _bonusEtherRates.length &&
        (_bonusDXCRates.length == 0 || _bonusPeriods.length == _bonusDXCRates.length) &&
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
        bonusDXCRates = _bonusDXCRates;

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

    modifier canSetAddress(address module) {
        require(votings[msg.sender] || (module == 0x0 && msg.sender == owner));
        _;
    }
}