pragma solidity ^0.4.11;

import "../VotingLib.sol";
import "../../Common.sol";
import "../BaseProposal.sol";

contract Withdrawal is BaseProposal {
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

    /*
    * @dev Delegates request of finishing to the Voting base contract
    */
    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.withdrawal(withdrawalWallet, withdrawalSum, dxc);
    }
}
