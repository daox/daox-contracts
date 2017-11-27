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
    mapping(address => uint) teamBonuses;
    mapping(address => uint) public depositedWei;
    uint[] teamBonusesArr;
    uint[] bonusPeriods;
    uint[] bonusRates;
    bool public refundableSoftCap = false;
    bool public refundable = false;
    uint newRate = 0;
    address public commissionContract;
    address serviceContract;
    address parentAddress;

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
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) onlyOwner {
        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;
    }

    function initBonuses(address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusRates) {
        require(_team.length == tokenPercents.length && _bonusPeriods.length == _bonusRates.length);
        team = _team;
        teamBonusesArr = tokenPercents;
        for(uint i = 0; i < _team.length; i++) {
            teamBonuses[_team[i]] = tokenPercents[i];
        }
        bonusPeriods = _bonusPeriods;
        bonusRates = _bonusRates;
    }

    function initHold(uint unholdTime) {
        if(unholdTime > 0) token.setHolding(unholdTime);
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
        if(commission) commissionRaised = commissionRaised + weiAmount;
        weiRaised = weiRaised + weiAmount;
        depositedWei[_sender] = depositedWei[_sender] + weiAmount;

        if(!isParticipant(_sender)) addParticipant(_sender);

        TokenPurchase(_sender, weiAmount, DAOLib.countTokens(token, weiAmount, bonusPeriods, bonusRates, rate, _sender));
    }

    function finish() onlyOwner {
        require(block.number >= endBlock);
        isCrowdsaleFinished = true;

        if(weiRaised >= softCap) DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team);
        else {
            refundableSoftCap = true;
            newRate = rate;
        }

        token.finishMinting();
    }

    function withdrawal(address _address, uint withdrawalSum) onlyVoting {
        assert(!_address.call.value(withdrawalSum*1 ether)());
    }

    function makeRefundable() external onlyVoting {
        refundable = true;
        newRate = token.totalSupply() / this.balance;
    }

    function refund() whenRefundable {
        require(teamBonuses[msg.sender] == 0);

        assert(!msg.sender.call.value(DAOLib.countRefundSum(token, rate, newRate)*1 wei)());
        token.burn(msg.sender);
    }

    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0);

        assert(!msg.sender.call.value(depositedWei[msg.sender])());
        token.burn(msg.sender);
        depositedWei[msg.sender] = 0;
    }

    /*
    Voting related methods
    */

    function addProposal(string _description, uint _duration, bytes32[] _options) {
        DAOLib.delegatedCreateProposal(votingFactory, _description, _duration, _options);
    }

    function addWithdrawal(string _description, uint _duration, uint _sum) {
        DAOLib.delegatedCreateWithdrawal(votingFactory, _description, _duration, _sum);
    }

    function addRefund(string _description, uint _duration) {
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
}