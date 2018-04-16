pragma solidity ^0.4.0;

import '../../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";

contract VotingDecisions is CrowdsaleDAOFields {

    function withdrawal(address _address, uint _withdrawalSum, bool _dxc) notInRefundableState onlyVoting external {
        lastWithdrawalTimestamp = block.timestamp;
        _dxc ? DXC.transfer(_address, _withdrawalSum) : _address.transfer(_withdrawalSum);
    }

    function makeRefundableByUser() external {
        require(lastWithdrawalTimestamp == 0 && block.timestamp >= created_at + withdrawalPeriod
        || lastWithdrawalTimestamp != 0 && block.timestamp >= lastWithdrawalTimestamp + withdrawalPeriod);
        makeRefundable();
    }

    function makeRefundableByVotingDecision() external onlyVoting {
        makeRefundable();
    }

    function makeRefundable() notInRefundableState private {
        refundable = true;
        newEtherRate = SafeMath.mul(this.balance * etherRate, multiplier) / tokensMintedByEther;
        newDXCRate = tokensMintedByDXC != 0 ? SafeMath.mul(DXC.balanceOf(this) * DXCRate, multiplier) / tokensMintedByDXC : 0;
    }

    function holdTokens(address _address, uint duration) onlyVoting external {
        token.hold(_address, duration);
    }

    modifier onlyVoting() {
        require(votings[msg.sender]);
        _;
    }

    modifier notInRefundableState {
        require(!refundable && !refundableSoftCap);
        _;
    }
}
