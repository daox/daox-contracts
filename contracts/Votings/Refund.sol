pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Refund is VotingFields {
    address baseVoting;

    function Refund(address _baseVoting, address _dao, bytes32 _description, uint _duration, uint _quorum){
        baseVoting = _baseVoting;
        votingType = "Refund";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, _quorum);
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.makeRefundableByVotingDecision();
    }

    function createOptions() private {
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }
}