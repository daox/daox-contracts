pragma solidity ^0.4.11;

import "./Users.sol";

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

    event ProposalCreated(uint proposalID);
    event OptionCreated(uint optionID);

    struct Option {
        uint votes;
        bytes256 description;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    struct Proposal {
        bytes256 description;
        bool proposalPassed;
        Option[] options;
        mapping (address => bool) voted;
        Option result;
        uint votesCount;
        uint duration; // UNIX
        uint created_at; // UNIX
        bool finished;
    }

    /*
    Public dao properties
    */
    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint8 public minVote; // in percents
    Proposal[] proposals;
    uint participantsCount;

    function DAO(address _address, string _name, string _description, uint8 _minVote, address[] _participants)
    Owned()
    {
        users = Users(_address);
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

    function addParticipant(address participantAddress) onlyOwner returns (bool) {
        require(users.doesExist(participantAddress));
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
        require(users.doesExist(_address));
        participants[_address] = false;
        participantsCount--;
    }

    function addProposal(string _description, uint _duration, bytes256[] _options) returns (uint) {
        require(_options.length >= 2);
        uint proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = stringToBytes256(_description);
        p.proposalPassed = false;
        p.created_at = block.timestamp;
        p.duration = _duration;

        for (uint i = 0; i < _options.length; i++) {
            p.options.push(Option(0, _options[i]));
            OptionCreated(i);
        }

        ProposalCreated(proposalID);
    }

    function addVote(uint proposalID, uint optionID, address _address) {
        require(proposalID < proposals.length && optionID < p.options.length);
        Proposal storage p = proposals[proposalID];
        require(!p.finished && !p.voted[msg.sender]);
        Option storage o = p.options[optionID];
        o.votes++;
        p.votesCount++;
    }

    function finishProposal(uint proposalID) returns (bool) {
        require(proposalID < proposals.length);
        Proposal storage p = proposals[proposalID];
        require(p.duration + p.created_at >= block.timestamp);
        p.finished = true;
        if(p.votesCount/participantsCount*100 < minVote) return;

        Option storage result = p.options[0];
        for(uint i = 0; i< p.options.length; i++) {
            if(result.votes < p.options[i].votes) result = p.options[i];
        }

        p.result = result;
    }

    function getProposalInfo(uint proposalID) public constant returns (bytes256) {
        return proposals[proposalID].description;
    }

    function getProposalOptions(uint proposalID) public constant returns(bytes256[]) {
        Option[] storage options = proposals[proposalID].options;
        bytes256[] memory optionDescriptions = new bytes256[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }

    function getProposals() public constant returns(bytes256[]) {
        bytes256[] memory _proposalDescriptions = new bytes256[](proposals.length);
        for(uint i = 0; i < proposals.length; i++) {
            _proposalDescriptions[i] = proposals[i].description;
        }

        return _proposalDescriptions;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }

    function stringToBytes256(string memory source) private returns (bytes256 result) {
        assembly {
            result := mload(add(source, 256))
        }
    }
}