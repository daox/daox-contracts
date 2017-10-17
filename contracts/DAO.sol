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

    struct Vote {
        bool inSupport;
        address voter;
    }

    struct Proposal {
        string description;
        bool proposalPassed;
        Vote[] votes;
        mapping (address => bool) voted;
        uint votesAmount;
        uint currentResult;
        uint duration; // UNIX
        uint created_at; // UNIX
        bool finished;
    }

    /*
    Public dao properties
    */
    mapping(address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    Proposal[] public proposals;

    function DAO(address _address, string _name, string _description)
    Owned()
    {
        users = Users(_address);
        name = _name;
        created_at = block.timestamp;
        description = _description;
    }

    function isParticipant(address participantAddress) constant returns(bool) {
        return participants[participantAddress];
    }

    function addParticipant(address participantAddress) returns(bool) {
        if (users.isExists(participantAddress)) {
            participants[participantAddress] = true;
        }

        return participants[participantAddress];
    }

    /*
    Not tested function
    */
    function addProposal(string _description, uint _duration) returns(uint) {
        uint proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = _description;
        p.proposalPassed = false;
        p.created_at = block.timestamp;
        p.duration = _duration;

        return proposalID;
    }

    function addVote(uint proposalID, bool isSupported) {
        require(proposalID < proposals.length);
        Proposal storage p = proposals[proposalID];
        require(!p.finished);
        require(!p.voted[msg.sender]);
        p.votesAmount++;
        if (isSupported) {
            p.currentResult++;
        } else {
            p.currentResult--;
        }
    }

    function finishProposal(uint proposalID) {
        require(proposalID < proposals.length);
        Proposal storage p = proposals[proposalID];
        require(p.duration + p.created_at >= block.timestamp);
        p.finished = true;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }
}