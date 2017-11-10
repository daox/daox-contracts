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
    uint withdrawalSum;

    struct Option {
        uint votes;
        bytes32 description;
    }

    modifier notFinished() {
        require(!finished);
        _;
    }

    function Voting(address _creator, string _description, uint _duration, bytes32[] _options, uint _sum){
        dao = DAOInterface(msg.sender);
        creator = _creator;
        description = Common.stringToBytes32(_description);
        finished = false;
        created_at = block.timestamp;
        duration = _duration;
        if(_sum > 0) {
            withdrawalSum = _sum;
            bytes32[] memory defaultOptions = new bytes32[](2);
            defaultOptions[0] = "yes";
            defaultOptions[1] = "no";
            createOptions(defaultOptions);
        } else {
            createOptions(_options);
        }
    }

    function addVote(uint optionID) notFinished {
        require(dao.isParticipant(msg.sender) && optionID < options.length && !voted[msg.sender]);
        Option storage o = options[optionID];
        voted[msg.sender] = true;
        votesCount++;
        o.votes++;
    }

    function finish() notFinished constant returns (bool)  {
        require(duration + created_at >= block.timestamp);
        finished = true;
        if(Common.percent(votesCount, dao.getParticipantsCount(), 2) < dao.getMinVotes()) return false;

        Option memory _result = options[0];
        for(uint i = 0; i< options.length; i++) {
            if(_result.votes < options[i].votes) _result = options[i];
        }

        result = _result;
        if(withdrawalSum > 0 && result.description == "yes") {
            assert(!creator.call.value(withdrawalSum*1 ether)());
        }
        return true;
    }

    function createOptions(bytes32[] _options) internal {
        for (uint i = 0; i < _options.length; i++) {
            options.push(Option(0, _options[i]));
        }
    }

    function getProposalOptions() public constant returns(bytes32[]) {
        bytes32[] memory optionDescriptions = new bytes32[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }
}
