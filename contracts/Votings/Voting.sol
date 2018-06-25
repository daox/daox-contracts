pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";
import "../DAO/ICrowdsaleDAO.sol";

contract Voting is VotingFields {

    /*
    * @dev Initiate storage variables for caller contract via `delegatecall`
    * @param _dao Address of dao where voting is creating
    * @param _name Voting name
    * @param _description Voting description
    * @param _duration Voting duration
    * @param _quorum Minimal percentage of token holders who must to take part in voting
    */
    function create(address _dao, bytes32 _name, bytes32 _description, uint _duration, uint _quorum)
    succeededCrowdsale(ICrowdsaleDAO(_dao))
    correctDuration(_duration)
    external
    {
        dao = ICrowdsaleDAO(_dao);
        name = Common.toString(_name);
        description = Common.toString(_description);
        duration = _duration;
        quorum = _quorum;
    }

    /*
    * @dev Add vote with passed optionID for the caller voting via `delegatecall`
    * @param _optionID ID of option
    */
    function addVote(uint _optionID) external notFinished canVote correctOption(_optionID) {
        require(block.timestamp - duration < created_at);
        uint tokensAmount = dao.token().balanceOf(msg.sender);
        options[_optionID].votes += tokensAmount;
        voted[msg.sender] = _optionID;
        votesCount += tokensAmount;

        dao.holdTokens(msg.sender, (duration + created_at) - now);
    }

    /*
    * @dev Finish voting for the caller voting contract via `delegatecall`
    * @param _optionID ID of option
    */
    function finish() external notFinished {
        require(block.timestamp - duration >= created_at);
        finished = true;
        if (keccak256(votingType) != keccak256("Withdrawal")) dao.DXC().transfer(dao.votings(this), dao.votingPrice());


        if (keccak256(votingType) == keccak256("Withdrawal")) return finishNotRegular();
        if (keccak256(votingType) == keccak256("Regular")) return finishRegular();

        //Other two cases of votings (`Module` and `Refund`) requires quorum
        if (Common.percent(options[1].votes, dao.token().totalSupply() - dao.teamTokensAmount(), 2) >= quorum) {
            result = options[1];
            return;
        }

        result = options[2];
    }

    /*
    * @dev Finish regular voting. Calls from `finish` function
    */
    function finishRegular() private {
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

    /*
    * @dev Finish non-regular voting. Calls from `finish` function
    */
    function finishNotRegular() private {
        if (options[1].votes > options[2].votes) result = options[1];
        else result = options[2];
    }

    /*
    * @dev Throws if caller is team member, not participant or has voted already
    */
    modifier canVote() {
        require(!dao.teamMap(msg.sender) && dao.isParticipant(msg.sender) && voted[msg.sender] == 0);
        _;
    }

    /*
    * @dev Throws if voting is finished already
    */
    modifier notFinished() {
        require(!finished);
        _;
    }

    /*
    * @dev Throws if crowdsale is not finished or if soft cap is not achieved
    */
    modifier succeededCrowdsale(ICrowdsaleDAO dao) {
        require(dao.crowdsaleFinished() && dao.fundsRaised() >= dao.softCap());
        _;
    }

    /*
    * @dev Throws if description of provided option ID is empty
    */
    modifier correctOption(uint optionID) {
        require(options[optionID].description != 0x0);
        _;
    }

    /*
    * @dev Throws if passed voting duration is not greater than minimal
    */
    modifier correctDuration(uint _duration) {
        require(_duration >= minimalDuration || keccak256(votingType) == keccak256("Module"));
        _;
    }
}
