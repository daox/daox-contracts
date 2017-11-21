pragma solidity ^0.4.11;

import "../Token/TokenInterface.sol";
import "../Users/UserInterface.sol";
import "../Votings/Voting.sol";
import "../Commission.sol";

contract Owned {
    address public owner;

    function Owned(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract CrowdsaleDAO is Owned {
    /*
    Emits when someone send ether to the contract
    and successfully buy tokens
    */
    event TokenPurchase (
        address beneficiary,
        uint weiAmount,
        uint tokensAmount
    );

    TokenInterface token;
    address public commissionContract;
    address serviceContract;
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
    uint[] teamBonusesArr;
    uint[] bonusPeriods;
    uint[] bonusRates;
    bool public refundable = false;
    uint newRate = 0;

    function CrowdsaleDAO(address _usersAddress, string _name, string _description,
    uint8 _minVote, address _ownerAddress, address _tokenAddress, address _serviceContract)
    Owned(_ownerAddress)
    {
        require(_usersAddress != 0x0 && _ownerAddress != 0x0 && _tokenAddress != 0x0 && _serviceContract != 0x0);
        users = UserInterface(_usersAddress);
        name = _name;
        created_at = block.timestamp;
        description = _description;
        minVote = _minVote;
        participants[_ownerAddress] = true;
        serviceContract = _serviceContract;
        token = TokenInterface(_tokenAddress);
        transferOwnership(_ownerAddress);
        commissionContract = new Commission(this);
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

    function handlePayment(address _sender, bool commission) CrowdsaleStarted validPurchase private {
        require(_sender != 0x0);

        uint weiAmount = msg.value;
        if(commission) commissionRaised = commissionRaised + weiAmount;
        weiRaised = weiRaised + weiAmount;

        TokenPurchase(_sender, weiAmount, DAOLib.countTokens(token, weiAmount, bonusPeriods, bonusRates, rate));
    }

    function finish() external onlyOwner {
        require(block.number >= endBlock);
        isCrowdsaleFinished = true;

        if(weiRaised >= softCap) DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, team, teamBonusesArr);
        else {
            refundable = true;
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

    /*
    Public dao properties
    */
    UserInterface public users;

    event VotingCreated(
        address votingAddress
    );

    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint8 public minVote; // in percents
    mapping(address => bytes32) public votings;
    uint participantsCount;

    function isParticipant(address participantAddress) constant returns (bool) {
        return participants[participantAddress];
    }

    function addParticipant(address participantAddress) isUser(participantAddress) isNotParticipant(participantAddress) returns (bool) {
        require(msg.sender == owner || msg.sender == participantAddress);
        participants[participantAddress] = true;
        participantsCount++;

        return participants[participantAddress];
    }

    function remove(address _participantAddress) onlyOwner {
        removeParticipant(_participantAddress);
    }

    function leave() {
        removeParticipant(msg.sender);
    }

    function removeParticipant(address _address) private {
        require(participants[_address]);
        participants[_address] = false;
        participantsCount--;
    }

    function addProposal(string _description, uint _duration, bytes32[] _options) onlyParticipant {
        addVoting(_description, _duration, _options, 0, 0);
    }

    function addWithdrawal(string _description, uint _duration, uint _sum) onlyParticipant {
        addVoting(_description, _duration, new bytes32[](0), _sum, 1);
    }

    function addRefund(string _description, uint _duration) onlyParticipant {
        addVoting(_description, _duration, new bytes32[](0), 0, 2);
    }

    function addVoting(string _description, uint _duration, bytes32[] _options, uint _sum, uint votingType) private {
        uint quorum = minVote;
        if(votingType == 2) quorum = 95;
        address voting = new Voting(msg.sender, _description, _duration, _options, _sum, votingType, quorum);
        votings[voting] = Common.stringToBytes32(_description);

        VotingCreated(voting);
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

    modifier whenRefundable() {
        require(refundable);
        _;
    }

    modifier isNotParticipant(address _userAddress) {
        require(participants[_userAddress]);
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
    }
}