pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Withdrawal is VotingFields {
    address baseVoting;
    uint public withdrawalSum;
    address public withdrawalWallet;

    function Withdrawal(address _baseVoting, address _dao, string _name, string _description, uint _duration, uint _sum, address _withdrawalWallet){
        require(_sum > 0 && _sum <= _dao.balance);
        baseVoting = _baseVoting;
        votingType = "Withdrawal";
        VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 0);
        withdrawalSum = _sum;
        withdrawalWallet = _withdrawalWallet;
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.withdrawal(withdrawalWallet, withdrawalSum);
    }

    function createOptions() private {
        options[1] = VotingLib.Option(0, "yes");
        options[2] = VotingLib.Option(0, "no");
    }

    function getOptions() external constant returns(uint[2] result) {
        for (uint i = 1; i < 3; i++) {
            result[i] = options[i].votes;
        }
    }
}
