pragma solidity ^0.4.0;

import "../Token/TokenInterface.sol";
import "../Users/UserInterface.sol";
import "../Votings/VotingFactoryInterface.sol";
import "./Owned.sol";

contract DAOFields is Owned {
    event VotingCreated(
        address votingAddress
    );

    /*
    Public interfaces which DAO will use
    */
    TokenInterface public token;
    VotingFactoryInterface public votingFactory;
    UserInterface public users;

    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint public minVote; // in percents
    mapping(address => bytes32) public votings;
    uint participantsCount;

    function DAOFields(address _ownerAddress, address _tokenAddress, address _votingFactory, address _usersAddress,
    string _name, string _description, uint _minVote)
    Owned(_ownerAddress)
    {
        users = UserInterface(_usersAddress);
        token = TokenInterface(_tokenAddress);
        votingFactory = VotingFactoryInterface(_votingFactory);

        name = _name;
        description = _description;
        minVote = _minVote;
        participants[_ownerAddress] = true;

        created_at = block.timestamp;

        transferOwnership(_ownerAddress);
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

    modifier isNotParticipant(address _userAddress) {
        require(participants[_userAddress]);
        _;
    }
}
