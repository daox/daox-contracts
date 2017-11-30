pragma solidity ^0.4.11;

import "../Commission.sol";
import "./DAOLib.sol";
import "./DAOFields.sol";

contract CrowdsaleDAO is DAOFields {
    /*
    Emits when someone send ether to the contract
    and successfully buy tokens
    */
    event TokenPurchase (
        address beneficiary,
        uint weiAmount,
        uint tokensAmount
    );

    uint public rate;
    uint public softCap;
    uint public hardCap;
    uint public startBlock;
    uint public endBlock;
    bool public isCrowdsaleFinished = false;
    uint public weiRaised = 0;
    uint public commissionRaised = 0;
    address[] team;
    address[] whiteListArr;
    mapping(address => bool) whiteList;
    mapping(address => uint) public teamBonuses;
    mapping(address => uint) public depositedWei;
    mapping(address => bool) public addressesWithCommission;
    uint[] teamBonusesArr;
    uint[] bonusPeriods;
    uint[] bonusRates;
    bool public refundableSoftCap = false;
    bool public refundable = false;
    uint newRate = 0;
    address public commissionContract;
    address serviceContract;
    address parentAddress;
    bool private canInitCrowdsaleParameters = true;
    bool private canInitBonuses = true;
    bool private canInitHold = true;
    uint tokenHoldTime = 0;

    function CrowdsaleDAO(address _usersAddress, string _name, string _description, uint8 _minVote,
    address _tokenAddress, address _votingFactory, address _serviceContract, address _ownerAddress, address _parentAddress)
    DAOFields(_ownerAddress, _tokenAddress, _votingFactory, _usersAddress, _name, _description, _minVote)
    {
        require(_serviceContract != 0x0);
        serviceContract = _serviceContract;
        commissionContract = new Commission(this);
        parentAddress = _parentAddress;
    }

    //ToDo: move these parameters to the contract constructor???
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) canInit(canInitCrowdsaleParameters) external {
        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;

        canInitCrowdsaleParameters = false;
    }

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusRates) external canInit(canInitBonuses) {
        require(_team.length == tokenPercents.length && _bonusPeriods.length == _bonusRates.length);
        team = _team;
        teamBonusesArr = tokenPercents;
        for(uint i = 0; i < _team.length; i++) {
            teamBonuses[_team[i]] = tokenPercents[i];
        }
        bonusPeriods = _bonusPeriods;
        bonusRates = _bonusRates;

        canInitBonuses = false;
    }

    function initHold(uint _tokenHoldTime) canInit(canInitHold) external {
        if(_tokenHoldTime > 0) tokenHoldTime = _tokenHoldTime;

        canInitHold = false;
    }

    function setWhiteList(address[] _addresses) {
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
        //forwardFunds();
    }

    function handleCommissionPayment(address _sender) onlyCommission payable {
        handlePayment(_sender, true);
    }

    function handlePayment(address _sender, bool commission) CrowdsaleStarted validPurchase(msg.value) private {
        require(_sender != 0x0);

        uint weiAmount = msg.value;
        if(commission) {
            commissionRaised = commissionRaised + weiAmount;
            addressesWithCommission[_sender] = true;
        }

        weiRaised = weiRaised + weiAmount;
        depositedWei[_sender] = depositedWei[_sender] + weiAmount;

        if(!isParticipant(_sender)) addParticipant(_sender);

        TokenPurchase(_sender, weiAmount, DAOLib.countTokens(token, weiAmount, bonusPeriods, bonusRates, rate, _sender));
    }

    function finish() onlyOwner {
        require(block.number >= endBlock);
        isCrowdsaleFinished = true;

        if(weiRaised >= softCap) DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, tokenHoldTime);
        else {
            refundableSoftCap = true;
            newRate = rate;
        }

        token.finishMinting();
    }

    function getCommissionTokens() onlyParticipant succeededCrowdsale {
        require(addressesWithCommission[msg.sender] && depositedWei[msg.sender] > 0);
        delete addressesWithCommission[msg.sender];
        assert(!serviceContract.call(bytes4(keccak256("getCommissionTokens(address,uint)")), msg.sender, depositedWei[msg.sender]));
    }

    function withdrawal(address _address, uint withdrawalSum) onlyVoting external {
        assert(!_address.call.value(withdrawalSum*1 ether)());
    }

    function makeRefundable() external onlyVoting {
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

    function addProposal(string _description, uint _duration, bytes32[10] _options) succeededCrowdsale onlyParticipant {
        DAOLib.delegatedCreateProposal(votingFactory, _description, _duration, _options);
    }

    function addWithdrawal(string _description, uint _duration, uint _sum) succeededCrowdsale {
        DAOLib.delegatedCreateWithdrawal(votingFactory, _description, _duration, _sum);
    }

    function addRefund(string _description, uint _duration) succeededCrowdsale {
        DAOLib.delegatedCreateRefund(votingFactory, _description, _duration);
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

    modifier succeededCrowdsale() {
        require(block.number >= endBlock && weiRaised >= softCap);
        _;
    }
}