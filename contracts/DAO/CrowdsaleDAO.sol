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

    /*
    * @dev Receives ether and forwards to the crowdsale module via a delegatecall with commission flag equal to false
    */
    function() payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, msg.sender, false);
    }

    /*
    * @dev Receives ether from commission contract and forwards to the crowdsale module
    *       via a delegatecall with commission flag equal to true
    * @param _sender Address which sent ether to commission contract
    */
    function handleCommissionPayment(address _sender) payable {
        DAOProxy.delegatedHandlePayment(crowdsaleModule, _sender, true);
    }

    /*
    * @dev Receives info about address which sent DXC tokens to current contract and about amount of sent tokens from
    *       DXC token contract and then forwards this data to the crowdsale module
    * @param _from Address which sent DXC tokens
    * @param _amount Amount of tokens which were sent
    */
    function handleDXCPayment(address _from, uint _amount) {
        DAOProxy.delegatedHandleDXCPayment(crowdsaleModule, _from, _amount);
    }

    /*
    * @dev Receives decision from withdrawal voting and forwards it to the voting decisions module
    * @param _address Address for withdrawal
    * @param _withdrawalSum Amount of ether/DXC tokens which must be sent to withdrawal address
    * @param _dxc boolean indicating whether withdrawal should be made through DXC tokens or not
    */
    function withdrawal(address _address, uint _withdrawalSum, bool _dxc) external {
        DAOProxy.delegatedWithdrawal(votingDecisionModule, _address, _withdrawalSum, _dxc);
    }

    /*
    * @dev Receives decision from refund voting and forwards it to the voting decisions module
    */
    function makeRefundableByVotingDecision() external {
        DAOProxy.delegatedMakeRefundableByVotingDecision(votingDecisionModule);
    }

    /*
    * @dev Called by voting contract to hold tokens of voted address.
    *      It is needed to prevent multiple votes with same tokens
    * @param _address Voted address
    * @param _duration Amount of time left for voting to be finished
    */
    function holdTokens(address _address, uint _duration) external {
        DAOProxy.delegatedHoldTokens(votingDecisionModule, _address, _duration);
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

    /*
    * @dev Checks if provided address has tokens of current DAO
    * @param _participantAddress Address of potential participant
    * @return boolean indicating if the address has at least one token
    */
    function isParticipant(address _participantAddress) external constant returns (bool) {
        return token.balanceOf(_participantAddress) > 0;
    }

    /*
    * @dev Function that is used to set address of token which will be distributed by DAO during the crowdsale and
    *      address of DXC token contract to use it for handling payment operations with DXC. Delegates call to state module
    * @param _tokenAddress Address of token that will be distributed during the crowdsale
    * @param _DXC Address of DXC contract
    */
    function initState(address _tokenAddress, address _DXC) public {
        DAOProxy.delegatedInitState(stateModule, _tokenAddress, _DXC);
    }

    /*
    * @dev Delegates parameters that describes conditions of crowdsale to the crowdsale module.
    * @param _softCap Minimal amount of funds that must be collected by DAO for crowdsale to be considered successful
    * @param _hardCap Maximal amount of funds that can be raised during the crowdsale
    * @param _etherRate Amount of tokens that will be minted for one ether
    * @param _DXCRate Amount of tokens that will be minted for one DXC
    * @param _startTime Unix timestamp that indicates the moment when crowdsale will start
    * @param _endTime Unix timestamp that indicates the moment when crowdsale will end
    * @param _dxcPayments Boolean indicating whether it is possible to invest via DXC token or not
    */
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _DXCRate, uint _startTime, uint _endTime, bool _dxcPayments) public {
        DAOProxy.delegatedInitCrowdsaleParameters(crowdsaleModule, _softCap, _hardCap, _etherRate, _DXCRate, _startTime, _endTime, _dxcPayments);
    }

    /*
    * @dev Delegates request of creating "regular" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _options List of options
    */
    function addRegular(string _name, string _description, uint _duration, bytes32[] _options) public {
        votings[DAOLib.delegatedCreateRegular(votingFactory, _name, _description, _duration, _options, this)] = true;
    }

    /*
    * @dev Delegates request of creating "withdrawal" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _sum Amount of funds that is supposed to be withdrawn
    * @param _withdrawalWallet Address for withdrawal
    * @param _dxc Boolean indicating whether withdrawal must be in DXC tokens or in ether
    */
    function addWithdrawal(string _name, string _description, uint _duration, uint _sum, address _withdrawalWallet, bool _dxc) public {
        votings[DAOLib.delegatedCreateWithdrawal(votingFactory, _name, _description, _duration, _sum, _withdrawalWallet, _dxc, this)] = true;
    }

    /*
    * @dev Delegates request of creating "refund" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    */
    function addRefund(string _name, string _description, uint _duration) public {
        votings[DAOLib.delegatedCreateRefund(votingFactory, _name, _description, _duration, this)] = true;
    }

    /*
    * @dev Delegates request of creating "module" voting and saves the address of created voting contract to votings list
    * @param _name Name for voting
    * @param _description Description for voting that will be created
    * @param _duration Time in seconds from current moment until voting will be finished
    * @param _module Number of module that must be replaced
    * @param _newAddress Address of new module
    */
    function addModule(string _name, string _description, uint _duration, uint _module, address _newAddress) public {
        votings[DAOLib.delegatedCreateModule(votingFactory, _name, _description, _duration, _module, _newAddress, this)] = true;
    }

    /*
    * @dev Delegates request for going into refundable state to voting decisions module
    */
    function makeRefundableByUser() public {
        DAOProxy.delegatedMakeRefundableByUser(votingDecisionModule);
    }

    /*
    * @dev Delegates request for refund to payment module
    */
    function refund() public {
        DAOProxy.delegatedRefund(paymentModule);
    }

    /*
    * @dev Delegates request for refund of soft cap to payment module
    */
    function refundSoftCap() public {
        DAOProxy.delegatedRefundSoftCap(paymentModule);
    }

    /*
    * @dev Delegates request for finish of crowdsale to crowdsale module
    */
    function finish() public {
        DAOProxy.delegatedFinish(crowdsaleModule);
    }

    /*
    * @dev Sets team addresses and bonuses for crowdsale
    * @param _team Array of addresses which represent team members' addresses
    * @param _tokenPercents Array of bonuses in percents which will go te every member in case of successful crowdsale
    * @param _bonusPeriods Array of timestamps which show when tokens will be minted with higher rate
    * @param _bonusEtherRates Array of ether rates for every bonus period
    * @param _bonusDXCRates Array of DXC rates for every bonus period
    * @param _teamHold Array of timestamps which show the hold duration of tokens for every team member
    * @param service Array of booleans which show whether member is a service address or not
    */
    function initBonuses(address[] _team, uint[] _tokenPercents, uint[] _bonusPeriods, uint[] _bonusEtherRates, uint[] _bonusDXCRates, uint[] _teamHold, bool[] _service) public onlyOwner(msg.sender) {
        require(
            _team.length == _tokenPercents.length &&
            _team.length == _teamHold.length &&
            _team.length == _service.length &&
            _bonusPeriods.length == _bonusEtherRates.length &&
        (_bonusDXCRates.length == 0 || _bonusPeriods.length == _bonusDXCRates.length) &&
        canInitBonuses &&
        (block.timestamp < startTime || canInitCrowdsaleParameters)
        );

        team = _team;
        teamHold = _teamHold;
        teamBonusesArr = _tokenPercents;
        teamServiceMember = _service;

        for(uint i = 0; i < _team.length; i++) {
            teamMap[_team[i]] = true;
            teamBonuses[_team[i]] = _tokenPercents[i];
        }

        bonusPeriods = _bonusPeriods;
        bonusEtherRates = _bonusEtherRates;
        bonusDXCRates = _bonusDXCRates;

        canInitBonuses = false;
    }

    /*
    * @dev Sets addresses which can be used to get funds via withdrawal votings
    * @param _addresses Array of addresses which will be used for withdrawals
    */
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