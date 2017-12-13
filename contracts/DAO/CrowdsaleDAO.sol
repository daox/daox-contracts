pragma solidity ^0.4.11;

import "./DAOLib.sol";
import "./CrowdsaleDAOFields.sol";
import "../Common.sol";
import "./Owned.sol";

contract CrowdsaleDAO is CrowdsaleDAOFields, Owned {
    /*
    Emits when someone send ether to the contract
    and successfully buy tokens
    */
    event TokenPurchase (
        address beneficiary,
        uint weiAmount,
        uint tokensAmount
    );

    address proxy;
    address[] whiteListArr;
    mapping(address => bool) whiteList;
    mapping(address => uint) public teamBonuses;
    uint[] bonusPeriods;
    uint[] bonusRates;
    bool public refundable = false;
    uint private lastWithdrawalTimestamp = 0;
    uint constant private withdrawalPeriod = 120 * 24 * 60 * 60;

    function CrowdsaleDAO(address _usersAddress, string _name, string _description, uint8 _minVote, address _proxy,
    address _tokenAddress, address _votingFactory, address _serviceContract, address _ownerAddress, address _parentAddress)
    Owned(_ownerAddress)
    {
        (proxy, name, description) = (_proxy, _name, _description);
        DAOLib.delegatedCreate(proxy, _usersAddress, _minVote, _tokenAddress, _votingFactory, _serviceContract, _ownerAddress, _parentAddress);
    }

    //ToDo: move these parameters to the contract constructor???
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) onlyOwner canInit(canInitCrowdsaleParameters) external {
        require(block.number < _startBlock && _softCap < _hardCap && _softCap != 0 && _rate != 0);
        DAOLib.delegatedInitCrowdsaleParameters(proxy, _softCap, _hardCap, _rate, _startBlock, _endBlock);
    }

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusRates) onlyOwner crowdsaleNotStarted external {
        require(_team.length == tokenPercents.length && _bonusPeriods.length == _bonusRates.length);
        team = _team;
        teamBonusesArr = tokenPercents;
        for(uint i = 0; i < _team.length; i++) {
            teamBonuses[_team[i]] = tokenPercents[i];
        }
        bonusPeriods = _bonusPeriods;
        bonusRates = _bonusRates;
    }

    function initHold(uint _tokenHoldTime) onlyOwner crowdsaleNotStarted external {
        require(_tokenHoldTime != 0);
        if(_tokenHoldTime > 0) tokenHoldTime = _tokenHoldTime;
    }

    function setWhiteList(address[] _addresses) onlyOwner {
        whiteListArr = _addresses;
        for(uint i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = true;
        }
    }

    function flushWhiteList() onlyVoting external {
        for(uint i = 0; i < whiteListArr.length; i++) {
            delete whiteList[whiteListArr[i]];
        }
    }

    function changeWhiteList(address _addr, bool res) onlyVoting external {
        if(!res) delete whiteList[_addr];
        whiteList[_addr] = true;
    }

    function() payable {
        handlePayment(msg.sender, false);
    }

    function handleCommissionPayment(address _sender) onlyCommission payable {
        handlePayment(_sender, true);
    }

    function handlePayment(address _sender, bool commission) CrowdsaleStarted validPurchase(msg.value) private {
        require(_sender != 0x0);

        DAOLib.delegatedHandlePayment(proxy, _sender, commission);
        if(!isParticipant(_sender)) addParticipant(_sender);
        uint weiAmount = msg.value;

        TokenPurchase(_sender, weiAmount, DAOLib.countTokens(token, weiAmount, bonusPeriods, bonusRates, rate, _sender));
    }

    function finish() onlyOwner {
        require(block.number >= endBlock);
        DAOLib.delegatedFinish(proxy);
    }

    function getCommissionTokens() onlyParticipant succeededCrowdsale {
        require(addressesWithCommission[msg.sender] && depositedWei[msg.sender] > 0);
        delete addressesWithCommission[msg.sender];
        assert(!serviceContract.call(bytes4(keccak256("getCommissionTokens(address,uint)")), msg.sender, depositedWei[msg.sender]));
    }

    function withdrawal(address _address, uint withdrawalSum) onlyVoting external {
        assert(!_address.call.value(withdrawalSum*1 ether)());
        lastWithdrawalTimestamp = block.timestamp;
    }

    function makeRefundableByUser() external {
        require(lastWithdrawalTimestamp != 0 && block.timestamp >= lastWithdrawalTimestamp + withdrawalPeriod);
        makeRefundable();
    }

    function makeRefundableByVotingDecision() external onlyVoting {
        makeRefundable();
    }

    function makeRefundable() private {
        require(!refundable);
        refundable = true;
        newRate = token.totalSupply() / this.balance;
    }

    function holdTokens(address _address, uint duration) onlyVoting external {
        token.hold(_address, duration);
    }

    function refund() whenRefundable {
        require(teamBonuses[msg.sender] == 0);

        token.burn(msg.sender);
        assert(!msg.sender.call.value(DAOLib.countRefundSum(token, rate, newRate)*1 wei)());
    }

    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0);

        token.burn(msg.sender);
        delete depositedWei[msg.sender];
        assert(!msg.sender.call.value(depositedWei[msg.sender])());
    }

    /*
    Voting related methods
    */

    function addProposal(string _description, uint _duration, bytes32[] _options) succeededCrowdsale onlyParticipant {
        DAOLib.delegatedCreateProposal(votingFactory, Common.stringToBytes32(_description), _duration, _options);
    }

    function addWithdrawal(string _description, uint _duration, uint _sum) succeededCrowdsale {
        DAOLib.delegatedCreateWithdrawal(votingFactory, Common.stringToBytes32(_description), _duration, _sum);
    }

    function addRefund(string _description, uint _duration) succeededCrowdsale {
        DAOLib.delegatedCreateRefund(votingFactory, Common.stringToBytes32(_description), _duration);
    }

    function addWhiteList(string _description, uint _duration, address _addr, uint action) succeededCrowdsale {
        DAOLib.delegatedCreateWhiteList(votingFactory, Common.stringToBytes32(_description), _duration, _addr, action);
    }

    /*
    DAO methods
    */

    function isParticipant(address _participantAddress) constant returns (bool) {
        DAOLib.delegateIsParticipant(parentAddress, _participantAddress);
    }

    function addParticipant(address _participantAddress) isUser(_participantAddress) isNotParticipant(_participantAddress) returns (bool) {
        DAOLib.delegateAddParticipant(parentAddress, _participantAddress);
    }

    function remove(address _participantAddress) onlyOwner {
        DAOLib.delegateRemove(parentAddress, _participantAddress);
    }

    function leave() {
        DAOLib.delegateRemove(parentAddress, msg.sender);
    }

    /*
    Modifiers
    */

    modifier whenRefundable() {
        require(refundable);
        _;
    }

    modifier whenRefundableSoftCap() {
        require(refundableSoftCap);
        _;
    }

    modifier onlyCommission() {
        require(commissionContract == msg.sender);
        _;
    }

    modifier CrowdsaleStarted() {
        require(block.number >= startBlock);
        _;
    }

    modifier validPurchase(uint value) {
        require(weiRaised + value < hardCap && block.number < endBlock);
        _;
    }

    modifier canInit(bool permission) {
        require(permission);
        _;
    }

    modifier crowdsaleNotStarted() {
        require(startBlock == 0 || block.number < startBlock);
        _;
    }

    modifier succeededCrowdsale() {
        require(block.number >= endBlock && weiRaised >= softCap);
        _;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }

    modifier onlyVoting() {
        require(votings[msg.sender] != 0x0);
        _;
    }

    modifier isUser(address _userAddress) {
        require(users.doesExist(_userAddress));
        _;
    }

    modifier isNotParticipant(address _userAddress) {
        require(participants[_userAddress]);
        _;
    }
}

