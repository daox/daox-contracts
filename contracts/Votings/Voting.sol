pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Voting is VotingFields {

    VotingLib.VotingType votingType;

    function create(address _dao, address _creator, bytes32 _description, uint _duration, uint _quorum){
        dao = DAOInterface(_dao);
        creator = _creator;
        description = _description;
        duration = _duration;
        quorum = _quorum;
    }

    function addVote(uint optionID) notFinished {
        require(dao.isParticipant(msg.sender) && optionID < options.length && !voted[msg.sender]);
        options[optionID].votes++;
        voted[msg.sender] = true;
        votesCount++;
    }

    function finish() notFinished constant returns (bool) {
        require(duration + created_at >= block.timestamp);
        finished = true;
        if(Common.percent(votesCount, dao.participantsCount(), 2) < quorum) return false;

        if(votingType == VotingLib.VotingType.Proposal) finishProposal();
        else finishNotProposal();

        return true;
    }

    function finishProposal() private {
        VotingLib.Option memory _result = options[0];
        for(uint i = 0; i< options.length; i++) {
            if(_result.votes < options[i].votes) _result = options[i];
        }
        result = _result;
    }

    function finishNotProposal() private {
        if(options[0].votes > options[1].votes) result = options[0];
        else result = options[1];
    }

    function createOptions(bytes32[] _options) internal {
        for (uint i = 0; i < _options.length; i++) {
            options.push(VotingLib.Option(0, _options[i]));
        }
    }

    function getProposalOptions() public constant returns(bytes32[]) {
        bytes32[] memory optionDescriptions = new bytes32[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }

    modifier notFinished() {
        require(!finished);
        _;
    }
}
