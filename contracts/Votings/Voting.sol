pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Voting is VotingFields {

    function create(address _dao, bytes32 _description, uint _duration, uint _quorum) external {
        dao = ICrowdsaleDAO(_dao);
        description = _description;
        duration = _duration;
        quorum = _quorum;
    }

    function addVote(uint optionID) external notFinished canVote(optionID) {
        require(block.timestamp - duration < created_at);
        uint tokensAmount = dao.token().balanceOf(msg.sender);
        options[optionID].votes += tokensAmount;
        voted[msg.sender] = true;
        votesCount += tokensAmount;

        dao.holdTokens(msg.sender, (duration + created_at) - now);
    }

    function finish() external notFinished {
        require(block.timestamp - duration >= created_at);
        finished = true;
        if (Common.percent(votesCount, dao.token().totalSupply(), 2) < quorum) return;

        if (keccak256(votingType) == keccak256(bytes32("Proposal"))) finishProposal();
        else finishNotProposal();
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

    function getProposalOptions() public constant returns(bytes32[]) {
        bytes32[] memory optionDescriptions = new bytes32[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }

    modifier canVote(uint optionID) {
        require(dao.teamBonuses(msg.sender) == 0 && dao.isParticipant(msg.sender) && optionID < options.length && !voted[msg.sender]);
        _;
    }

    modifier notFinished() {
        require(!finished);
        _;
    }
}
