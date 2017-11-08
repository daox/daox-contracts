pragma solidity ^0.4.11;

import "../Users.sol";
//import "./Token.sol";

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender != owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract DAO is Owned {
    /*
    Reference to external contract
    */
    Users public users;

    event VotingCreated(
    uint votingID,
    bytes32[] options
    );
    event OptionCreated(uint optionID);

    struct Option {
    uint votes;
    bytes32 description;
    }

    struct Voting {
    address creator;
    bytes32 description;
    bool votingPassed;
    Option[] options;
    mapping (address => bool) voted;
    Option result;
    uint votesCount;
    uint duration; // UNIX
    uint created_at; // UNIX
    bool finished;
    uint withdrawalSum;
    }

    /*
    Public dao properties
    */
    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint8 public minVote; // in percents
    Voting[] votings;
    uint participantsCount;


    function DAO(address _usersAddress, string _name, string _description, uint8 _minVote, address[] _participants, address _owner)
    Owned(_owner)
    {
        users = Users(_usersAddress);
        name = _name;
        created_at = block.timestamp;
        description = _description;
        minVote = _minVote;
        for(uint i =0; i<_participants.length; i++) {
            require(users.doesExist(_participants[i]));
            participants[_participants[i]] = true;
        }
    }

    function isParticipant(address participantAddress) constant returns (bool) {
        return participants[participantAddress];
    }

    function addParticipant(address participantAddress) returns (bool) {
        require(users.doesExist(participantAddress) && !isParticipant(participantAddress)
        && (msg.sender == owner || msg.sender == participantAddress));
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
        require(_options.length >= 2);
        uint proposalID = votings.length++;
        createBasicVoting(proposalID, _description, _duration, _options);

        VotingCreated(proposalID, _options);
    }

    function addWithdrawal(string _description, uint _duration, uint _sum) onlyOwner {
        uint proposalID = votings.length++;
        bytes32[] memory _options = new bytes32[](2);
        _options[0] = "yes";
        _options[1] = "no";
        Voting storage v  = createBasicVoting(proposalID, _description, _duration, _options);
        v.withdrawalSum = _sum;

        VotingCreated(proposalID, _options);
    }

    function createBasicVoting(uint proposalID, string _description, uint _duration, bytes32[] _options) private returns(Voting storage) {
        Voting storage v = votings[proposalID];
        v.creator = msg.sender;
        v.description = stringToBytes32(_description);
        v.votingPassed = false;
        v.created_at = block.timestamp;
        v.duration = _duration;

        for (uint i = 0; i < _options.length; i++) {
            v.options.push(Option(0, _options[i]));
        }

        return v;
    }

    function addVote(uint proposalID, uint optionID, address _votingUser) {
        Voting storage v = votings[proposalID];
        require(participants[_votingUser] && proposalID < votings.length && optionID < v.options.length);
        require(!v.finished && !v.voted[msg.sender]);
        Option storage o = v.options[optionID];
        v.voted[_votingUser] = true;
        o.votes++;
        v.votesCount++;
    }

    function finishProposal(uint proposalID) returns (bool) {
        require(proposalID < votings.length);
        Voting storage v = votings[proposalID];
        require(v.duration + v.created_at >= block.timestamp);
        v.finished = true;
        if(v.votesCount/participantsCount*100 < minVote) return;

        Option storage result = v.options[0];
        for(uint i = 0; i< v.options.length; i++) {
            if(result.votes < v.options[i].votes) result = v.options[i];
        }

        v.result = result;
        if(v.withdrawalSum > 0 && v.result.description == "yes") {
            assert(!owner.call.value(v.withdrawalSum*1 ether)());
        }
    }

    function getProposalInfo(uint proposalID) public constant returns (bytes32) {
        return votings[proposalID].description;
    }

    function getProposalOptions(uint proposalID) public constant returns(bytes32[]) {
        Option[] storage options = votings[proposalID].options;
        bytes32[] memory optionDescriptions = new bytes32[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }

    function getProposals() public constant returns(bytes32[]) {
        bytes32[] memory _proposalDescriptions = new bytes32[](votings.length);
        for(uint i = 0; i < votings.length; i++) {
            _proposalDescriptions[i] = votings[i].description;
        }

        return _proposalDescriptions;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }

    function stringToBytes32(string memory source) private returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }
    }
}