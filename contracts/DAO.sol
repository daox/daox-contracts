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
    Users users;

    struct Vote {
        bool inSupport;
        address voter;
    }

    struct Proposal {
        string description;
        bool proposalPassed;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    /*
    Public dao properties
    */
    mapping(address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    Proposal[] proposals;

    function DAO(address usersAddress, string name, string description)
    Owned()
    {
        users = Users(usersAddress);
        name = name;
        created_at = block.timestamp;
        description = description;
    }

    function isParticipant(address participantAddress) constant returns(bool) {
        return participants[participantAddress] == true;
    }

    function addParticipant(address participantAddress) returns(bool) {
        if (users.isExist(participantAddress)) {
            participants[participantAddress] = true;
        }

        return participants[participantAddress];
    }

    /*
    Not tested function
    */
    function addProposal(string description) {
        uint proposalID = ++proposals.length;
        Proposal p = proposals[proposalID];
        p.description = description;
        p.proposalPassed = false;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }
}