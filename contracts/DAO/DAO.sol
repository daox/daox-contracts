pragma solidity ^0.4.11;

import "../UserInterface.sol";
import "./DAOInterface.sol";
import "../Votings/Proposal.sol";
import "../Votings/Withdrawal.sol";

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

contract DAO is Owned, DAOInterface {
    /*
    Reference to external contract
    */
    UserInterface public users;

    event VotingCreated(
        address votingAddress
    );

    /*
    Public dao properties
    */
    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint8 public minVote; // in percents
    mapping(address => string) public votings;
    uint participantsCount;


    function DAO(address _address, string _name, string _description, uint8 _minVote, address[] _participants)
    Owned()
    {
        users = UserInterface(_address);
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
        address proposal = new Proposal(msg.sender, _description, _duration, _options);
        votings[proposal] = _description;

        VotingCreated(proposal);
    }

    function addWithdrawal(string _description, uint _duration, uint _sum) onlyOwner {
        require(_sum > 0);
        address withdrawal = new Withdrawal(msg.sender, _description, _duration, _sum);
        votings[withdrawal] = _description;

        VotingCreated(withdrawal);
    }


    function getMinVotes() public constant returns(uint8) {
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