pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Withdrawal is VotingFields {
    address baseVoting;
    uint public withdrawalSum;
    address public withdrawalWallet;
    bool public dxt;

    function Withdrawal(address _baseVoting, address _dao, bytes32 _description, uint _duration, uint _sum, address _withdrawalWallet, bool _dxt) {
        require(_sum > 0 && VotingLib.isValidWithdrawal(ICrowdsaleDAO(_dao), _sum, _dxt));
        baseVoting = _baseVoting;
        votingType = "Withdrawal";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, 0);
        withdrawalSum = _sum;
        withdrawalWallet = _withdrawalWallet;
        dxt = _dxt;
        createOptions();
    }

    function getOptions() external constant returns(uint[2]) {
        return [options[1].votes, options[2].votes];
    }

    function addVote(uint optionID) public {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.withdrawal(withdrawalWallet, withdrawalSum, dxt);
    }

    function createOptions() private {
        options[1] = VotingLib.Option(0, "yes");
        options[2] = VotingLib.Option(0, "no");
    }
}
