pragma solidity ^0.4.0;

import "../Common.sol";
import "../DAO/DAOInterface.sol";

contract Voting {

    enum VotingType {Proposal, Withdrawal, Refund}

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
    uint public quorum;
    uint votingType;

    struct Option {
    uint votes;
    bytes32 description;
    }

    function Voting(address _creator, string _description, uint _duration, bytes32[] _options, uint _sum, uint _votingType, uint _quorum){
        dao = DAOInterface(msg.sender);
        creator = _creator;
        description = Common.stringToBytes32(_description);
        finished = false;
        created_at = block.timestamp;
        duration = _duration;
        quorum = _quorum;
        votingType = _votingType;

        if(votingType != uint(VotingType.Proposal)) createOptions(createDefaultOptions());
        else createOptions(_options);

        if(votingType == uint(VotingType.Withdrawal)) withdrawalSum = _sum;
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
        if(Common.percent(votesCount, dao.participantsCount(), 2) < quorum) return false;

        Option memory _result = options[0];
        for(uint i = 0; i< options.length; i++) {
            if(_result.votes < options[i].votes) _result = options[i];
        }
        result = _result;
        if(votingType==uint(VotingType.Withdrawal) && result.description == "yes") dao.withdrawal(creator, withdrawalSum);
        if(votingType==uint(VotingType.Refund) && result.description == "yes") dao.makeRefundable();

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

    function createDefaultOptions() private constant returns (bytes32[]) {
        bytes32[] memory defaultOptions = new bytes32[](2);
        defaultOptions[0] = "yes";
        defaultOptions[1] = "no";

        return defaultOptions;
    }

    modifier notFinished() {
        require(!finished);
        _;
    }
}
