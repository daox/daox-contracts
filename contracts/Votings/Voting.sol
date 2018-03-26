pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Voting is VotingFields {

	function create(address _dao, bytes32 _name, bytes32 _description, uint _duration, uint _quorum) succeededCrowdsale(ICrowdsaleDAO(_dao)) correctDuration(_duration) external {
        dao = ICrowdsaleDAO(_dao);
        name = toString(_name);
        description = toString(_description);
        duration = _duration;
        quorum = _quorum;
    }

    function toString(bytes32 _bytes) internal constant returns(string) {
        bytes memory arrayTemp = new bytes(32);
        uint currentLength = 0;

        for (uint i = 0; i < 32; i++) {
            arrayTemp[i] = _bytes[i];
            if (arrayTemp[i] != 0) currentLength+=1;
        }

        bytes memory arrayRes = new bytes(currentLength);
        for (i = 0; i < currentLength; i++) {
            arrayRes[i] = arrayTemp[i];
        }

        return string(arrayRes);
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
        if (keccak256(votingType) == keccak256(bytes32("Withdrawal"))) return finishNotProposal();
        if (keccak256(votingType) == keccak256(bytes32("Proposal"))) return finishProposal();

        //Other two cases of votings (`Module` and `Refund`) requires quorum
        if (Common.percent(options[1].votes, dao.token().totalSupply() - dao.teamTokensAmount(), 2) >= quorum) {
            result = options[1];
            return;
        }

        result = options[2];
    }

    function finishProposal() private {
        VotingLib.Option memory _result = options[1];
        bool equal = false;
        for (uint i = 2; i < options.length; i++) {
            if (_result.votes == options[i].votes) equal = true;
            else if (_result.votes < options[i].votes) {
                _result = options[i];
                equal = false;
            }
        }
        if (!equal) result = _result;
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

    modifier correctDuration(uint _duration) {
        require(_duration >= minimalDuration);
        _;
    }
}
