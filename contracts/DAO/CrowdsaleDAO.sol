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

    TokenInterface token;
    uint public rate;
    uint softCap;
    uint hardCap;
    uint startBlock;
    uint endBlock;
    bool isCrowdsaleFinished = false;
    uint public weiRaised = 0;

    function CrowdsaleDAO(address _usersAddress, string _name, string _description, uint8 _minVote, address _owner, address _tokenAddress)
    Owned(_owner)
    {
        users = UserInterface(_usersAddress);
        name = _name;
        created_at = block.timestamp;
        description = _description;
        minVote = _minVote;
        participants[_owner] = true;
        token = TokenInterface(_tokenAddress);
    }

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) public {
        softCap = _softCap;
        hardCap = _hardCap;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;
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
        if (value * rate > hardCap) return false;
        if (block.number > endBlock) return false;
        //if (token.mintingFinished == true) return false; ToDo: do we need to check that?

        return true;
    }

    function finish() public onlyOwner {
        require(endBlock >= block.number);
        isCrowdsaleFinished = true;

        token.finishMinting();
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
    mapping(address => string) public votings;
    uint participantsCount;

    modifier isUser(address _userAddress) {
        require(users.doesExist(_userAddress));
        _;
    }

    modifier isNotParticipant(address _userAddress) {
        require(participants[_userAddress]);
        _;
    }

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

    function addVoting(string _description, uint _duration, bytes32[] _options, uint _sum) onlyParticipant {
        address voting = new Voting(msg.sender, _description, _duration, _options, _sum);
        votings[voting] = _description;

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
}