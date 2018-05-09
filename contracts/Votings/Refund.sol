pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "../Common.sol";
import "./BaseProposal.sol";

contract Refund is BaseProposal {
    function Refund(address _baseVoting, address _dao, string _name, string _description, uint _duration) {
        baseVoting = _baseVoting;
        votingType = "Refund";
        VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 90);
        createOptions();
    }

    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.makeRefundableByVotingDecision();
    }
}