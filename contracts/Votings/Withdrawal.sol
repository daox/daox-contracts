pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Withdrawal is VotingFields {
    address baseVoting;
    uint public withdrawalSum;
    address public withdrawalWallet;
    bool public dxc;

    function Withdrawal(address _baseVoting, address _dao, string _name, string _description, uint _duration, uint _sum, address _withdrawalWallet, bool _dxc) {
        require(_sum > 0 && VotingLib.isValidWithdrawal(_dao, _sum, _dxc));
        baseVoting = _baseVoting;
        votingType = "Withdrawal";
        VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 0);
        withdrawalSum = _sum;
        withdrawalWallet = _withdrawalWallet;
        dxc = _dxc;
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
        if(result.description == "yes") dao.withdrawal(withdrawalWallet, withdrawalSum, dxc);
    }

    function createOptions() private {
        options[1] = VotingLib.Option(0, "yes");
        options[2] = VotingLib.Option(0, "no");
    }
}
