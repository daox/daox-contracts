pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Refund is VotingFields {
    address baseVoting;

    function Refund(address _baseVoting, address _dao, bytes32 _description, uint _duration) {
        baseVoting = _baseVoting;
        votingType = "Refund";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, 90);
        createOptions();
    }

    function getOptions() public constant returns(uint[2]) {
        return [options[1].votes, options[2].votes];
    }

    function addVote(uint optionID) public {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.makeRefundableByVotingDecision();
    }

    function createOptions() private {
        options[1] = VotingLib.Option(0, "yes");
        options[2] = VotingLib.Option(0, "no");
    }
}