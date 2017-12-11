pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Withdrawal is VotingFields {
    address baseVoting;
    uint public withdrawalSum;
    VotingLib.VotingType constant votingType = VotingLib.VotingType.Withdrawal;

    function Withdrawal(address _baseVoting, address _dao, address _creator, string _description, uint _duration, uint _sum, uint _quorum){
        baseVoting = _baseVoting;
        VotingLib.delegatecallCreate(baseVoting, _dao, _creator, Common.stringToBytes32(_description), _duration, _quorum);
        withdrawalSum = _sum;
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.withdrawal(creator, withdrawalSum);
    }

    function createOptions() private {
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }

    function getOptions() external constant returns(uint[2] result) {
        for (uint i = 0; i < 2; i++) {
            result[i] = options[i].votes;
        }
    }
}
