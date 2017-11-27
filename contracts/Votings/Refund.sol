pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Refund is VotingFields {
    address baseVoting;
    VotingLib.VotingType constant votingType = VotingLib.VotingType.Refund;

    function Refund(address _baseVoting, address _dao, address _creator, string _description, uint _duration, uint _quorum){
        baseVoting = _baseVoting;
        VotingLib.delegatecallCreate(baseVoting, _dao, _creator, Common.stringToBytes32(_description), _duration, _quorum);
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.makeRefundable();
    }

    function createOptions() private {
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }
}