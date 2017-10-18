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
        string description;
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
    Proposal[] public proposals;

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

    function addParticipant(address participantAddress) returns (bool) {
        if (users.isExists(participantAddress)) {
            participants[participantAddress] = true;
        }

        return participants[participantAddress];
    }

    /*
    Not tested function
    */
    function addProposal(string _description, uint _duration, string[] _options) returns (uint) {
        uint proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = _description;
        p.proposalPassed = false;
        p.created_at = block.timestamp;
        p.duration = _duration;
        p.options = _options;

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

    function finishProposal(uint proposalID) {
        require(proposalID < proposals.length);
        Proposal storage p = proposals[proposalID];
        require(p.duration + p.created_at >= block.timestamp);
        p.finished = true;
        if(!(p.votesCount/users.length)*100 >= minVote) return;

        Option result;
        for(uint i = 0; i< p.options.length; i++) {
            if(result.votes.length < p.options[i].length) result = p.options[i];
        }

        p.result = result;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }
}