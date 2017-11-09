pragma solidity ^0.4.11;
//
//import "../Common.sol";
//import "../DAO/DAO.sol";
//
//contract Voting {
//
//    using Common for string;
//
//    DAO dao;
//    address creator;
//    bytes32 description;
//    bool votingPassed;
//    Option[] options;
//    mapping (address => bool) voted;
//    Option result;
//    uint votesCount;
//    uint duration; // UNIX
//    uint created_at; // UNIX
//    bool finished;
//
//    struct Option {
//        uint votes;
//        bytes32 description;
//    }
//
//    function Voting(address _creator, string _description, uint _duration){
//        dao = DAO(msg.sender);
//        creator = _creator;
//        description = _description.stringToBytes32();
//        votingPassed = false;
//        finished = false;
//        created_at = block.timestamp;
//        duration = _duration;
//    }
//
//    function addVote(uint optionID)  {
//        require(dao.participants[msg.sender] && optionID < options.length && !v.finished && !voted[msg.sender]);
//        Option storage o = options[optionID];
//        v.voted[_votingUser] = true;
//        votesCount++;
//        o.votes++;
//    }
//
//    function finish() constant returns (bool) {
//        require(duration + created_at >= block.timestamp);
//        finished = true;
//        if(votesCount < dao.minVote) return false;
//
//        Option storage _result = options[0];
//        for(uint i = 0; i< options.length; i++) {
//            if(_result.votes < options[i].votes) _result = options[i];
//        }
//
//        result = _result;
//
//        return true;
//        if(withdrawalSum > 0 && result.description == "yes") {
//            assert(!owner.call.value(withdrawalSum*1 ether)());
//        }
//    }
//
//    function createOptions(bytes32[] _options) internal {
//        for (uint i = 0; i < _options.length; i++) {
//            options.push(Option(0, _options[i]));
//        }
//    }
//
//    modifier onlyDAO {
//        require(participants[msg.sender] == true);
//        _;
//    }
//}
