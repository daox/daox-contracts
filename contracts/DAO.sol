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

    struct Option {
        address[] votes;
        bytes32 description;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    struct Proposal {
        string description;
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

    function DAO(address _address, string _name, string _description, uint8 _minVote)
    Owned()
    {
        users = Users(_address);
        name = _name;
        created_at = block.timestamp;
        description = _description;
        minVote = _minVote;
    }

    function isParticipant(address participantAddress) constant returns (bool) {
        return participants[participantAddress];
    }

    function addParticipant(address participantAddress) onlyOwner returns (bool) {
        if (users.doesExist(participantAddress)) {
            participants[participantAddress] = true;
            participantsCount++;
        }

        return participants[participantAddress];
    }

    function removeParticipant(address _participantAddress) onlyOwner {
        participants[_participantAddress] = false;
        participantsCount--;
    }

    function addProposal(string _description, uint _duration, bytes32[] _options) returns (uint) {
        uint proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = _description;
        p.proposalPassed = false;
        p.created_at = block.timestamp;
        p.duration = _duration;

        for (uint i = 0; i < _options.length; i++) {
            Option storage option = p.options[i];
            option.description = _options[i];
            p.options[i] = option;
        }

        return proposalID;
    }

    function addVote(uint proposalID, uint optionID, address _address) {
        require(proposalID < proposals.length && optionID < p.options.length);
        Proposal storage p = proposals[proposalID];
        require(!p.finished && !p.voted[msg.sender]);
        Option storage o = p.options[optionID];
        o.votes[o.votes.length+1] = _address;
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
            if(result.votes.length < p.options[i].votes.length) result = p.options[i];
        }

        p.result = result;
    }

    function getProposalInfo(uint proposalID) public constant returns (string) {
        return proposals[proposalID].description;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }
}