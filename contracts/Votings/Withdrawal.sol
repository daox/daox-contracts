pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Withdrawal is VotingFields {
    address baseVoting;
    uint public withdrawalSum;
    address public withdrawalWallet;

    function Withdrawal(address _baseVoting, address _dao, bytes32 _description, uint _duration, uint _sum, uint _quorum, address _withdrawalWallet){
        require(_sum > 0 && sum * 1 ether <= _dao.balance);
        baseVoting = _baseVoting;
        votingType = "Withdrawal";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, _quorum);
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
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }

    function getOptions() external constant returns(uint[2] result) {
        for (uint i = 0; i < 2; i++) {
            result[i] = options[i].votes;
        }
    }
}
