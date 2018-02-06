pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Voting is VotingFields {

    function create(address _dao, bytes32 _description, uint _duration, uint _quorum) succeededCrowdsale(ICrowdsaleDAO(_dao)) external {
        dao = ICrowdsaleDAO(_dao);
        description = _description;
        duration = _duration;
        quorum = _quorum;
    }

    function addVote(uint optionID) external notFinished canVote correctOption(optionID) {
        require(block.timestamp - duration < created_at);
        uint tokensAmount = dao.token().balanceOf(msg.sender);
        options[optionID].votes += tokensAmount;
        voted[msg.sender] = optionID;
        votesCount += tokensAmount;

        dao.holdTokens(msg.sender, (duration + created_at) - now);
    }

    function finish() external notFinished {
        require(block.timestamp - duration >= created_at);
        finished = true;
        if (keccak256(votingType) == keccak256(bytes32("Withdrawal"))) {
            finishNotProposal();
        }
        if (keccak256(votingType) == keccak256(bytes32("Proposal"))) {
            finishProposal();
        }

        //Other two cases of votings (`Module` and `Refund`) requires quorum
        if (Common.percent(votesCount, dao.token().totalSupply() - dao.teamTokensAmount(), 2) < quorum) return;
        finishNotProposal();
    }

    function finishProposal() private {
        VotingLib.Option memory _result = options[1];
        for (uint i = 1; i< options.length; i++) {
            if(_result.votes < options[i].votes) _result = options[i];
        }
        result = _result;
    }

    function finishNotProposal() private {
        if (options[1].votes > options[2].votes) result = options[1];
        else result = options[2];
    }

    modifier canVote() {
        require(dao.teamBonuses(msg.sender) == 0 && dao.isParticipant(msg.sender) && voted[msg.sender] == 0);
        _;
    }

    modifier notFinished() {
        require(!finished);
        _;
    }

    modifier succeededCrowdsale(ICrowdsaleDAO dao) {
        require(dao.crowdsaleFinished() && dao.weiRaised() >= dao.softCap());
        _;
    }

    modifier correctOption(uint optionID) {
        require(options[optionID].description != 0x0);
        _;
    }
}
