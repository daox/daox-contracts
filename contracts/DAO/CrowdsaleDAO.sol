pragma solidity ^0.4.11;

import "../Token/TokenInterface.sol";
import "../Users/UserInterface.sol";
import "../Votings/Voting.sol";

contract Owned {
    address public owner;

    function Owned(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender != owner);
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

    event InitCrowdsaleParameters(
        uint soft,
        uint hard,
        uint start,
        uint end,
        uint rate
    );

    TokenInterface token;
    address serviceContract;
    uint public rate;
    uint public softCap;
    uint public hardCap;
    uint public startBlock;
    uint public endBlock;
    bool public isCrowdsaleFinished = false;
    uint public weiRaised = 0;
    bool refundable = false;
    uint newRate = 0;

    function CrowdsaleDAO(address _usersAddress, string _name, string _description,
    uint8 _minVote, address _ownerAddress, address _tokenAddress, address _serviceContract)
    Owned(_ownerAddress)
    {
        users = UserInterface(_usersAddress);
        name = _name;
        created_at = block.timestamp;
        description = _description;
        minVote = _minVote;
        participants[_ownerAddress] = true;
        serviceContract = _serviceContract;
        token = TokenInterface(_tokenAddress);
    }

    //ToDo: move these parameters to the contract constructor???
    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) public {
        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;

        InitCrowdsaleParameters(_softCap, _hardCap, _rate, _startBlock, _endBlock);
    }

    function() payable {
        require(msg.sender != 0x0);
        require(validPurchase(msg.value));
        uint weiAmount = msg.value;

        //ToDo: rate in ethers or weis?
        uint tokensAmount = weiAmount * rate;

        // update state
        weiRaised = weiRaised + weiAmount;

        token.mint(msg.sender, tokensAmount);
        TokenPurchase(msg.sender, weiAmount, tokensAmount);

        //forwardFunds();
    }

    function validPurchase(uint value) constant returns(bool) {
        if (weiRaised + value > hardCap) return false;
        if (block.number > endBlock) return false;
        //if (token.mintingFinished == true) return false; ToDo: do we need to check that?

        return true;
    }

    function finish() public onlyOwner {
        require(endBlock >= block.number);
        isCrowdsaleFinished = true;
        token.finishMinting();

        if(weiRaised >= softCap) {
            uint commission = (weiRaised/100)*4;
            assert(!serviceContract.call.value(commission*1 wei)());
        }
    }

    function withdrawal(address _address, uint withdrawalSum) onlyVoting {
        assert(!_address.call.value(withdrawalSum*1 ether)());
    }

    function makeRefundable() onlyVoting {
        refundable = true;
        newRate = token.totalSupply() / this.balance;
    }

    function refund() whenRefundable {
        uint multiplier = 1000;
        uint newRateToOld = newRate*multiplier / rate;
        uint weiSpent = token.balanceOf(msg.sender) / rate;
        uint weiToRefund = weiSpent*multiplier / newRateToOld;

        assert(!msg.sender.call.value(weiToRefund*1 wei)());
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

    function addProposal(string _description, uint _duration, bytes32[] _options, uint _sum) onlyParticipant {
        addVoting(_description, _duration, _options, 0, 0);
    }

    function addWithdrawal(string _description, uint _duration, bytes32[] _options, uint _sum) onlyParticipant {
        addVoting(_description, _duration, new bytes32[](0), _sum, 1);
    }

    function addRefund(string _description, uint _duration, bytes32[] _options, uint _sum) onlyParticipant {
        addVoting(_description, _duration, new bytes32[](0), 0, 2);
    }

    function addVoting(string _description, uint _duration, bytes32[] _options, uint _sum, uint votingType) private {
        uint quorum = minVote;
        if(votingType == 2) quorum = 95;
        address voting = new Voting(msg.sender, _description, _duration, _options, _sum, votingType, quorum);
        votings[voting] = Common.stringToBytes32(_description);

        VotingCreated(voting);
    }

    function getMinVotes() public constant returns(uint) {
        return minVote;
    }

    function getParticipantsCount() public constant returns(uint) {
        return participantsCount;
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
}