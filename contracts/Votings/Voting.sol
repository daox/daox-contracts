pragma solidity ^0.4.0;

import "../Common.sol";
import "../DAO/DAOInterface.sol";

contract Voting {
    DAOInterface dao;
    address public creator;
    bytes32 public description;
    Option[] options;
    mapping (address => bool) public voted;
    Option result;
    uint public votesCount;
    uint public duration; // UNIX
    uint public created_at; // UNIX
    bool public finished;

    struct Option {
        uint votes;
        bytes32 description;
    }

    function Voting(address _creator, string _description, uint _duration){
        dao = DAOInterface(msg.sender);
        creator = _creator;
        description = Common.stringToBytes32(_description);
        finished = false;
        created_at = block.timestamp;
        duration = _duration;
    }

    function addVote(uint optionID) {
        require(dao.isParticipant(msg.sender) && optionID < options.length && !finished && !voted[msg.sender]);
        Option storage o = options[optionID];
        voted[msg.sender] = true;
        votesCount++;
        o.votes++;
    }

    function finish() constant returns (bool) {
        require(duration + created_at >= block.timestamp);
        finished = true;
        if(Common.percent(votesCount, dao.getParticipantsCount(), 2) < dao.getMinVotes()) return false;

        Option storage _result = options[0];
        for(uint i = 0; i< options.length; i++) {
            if(_result.votes < options[i].votes) _result = options[i];
        }

        result = _result;

        return true;
    }

    function createOptions(bytes32[] _options) internal {
        for (uint i = 0; i < _options.length; i++) {
            options.push(Option(0, _options[i]));
        }
    }

    function getProposalOptions(uint proposalID) public constant returns(bytes32[]) {
        bytes32[] memory optionDescriptions = new bytes32[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }
}
