pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";

contract VotingDecisions is CrowdsaleDAOFields {

    function withdrawal(address _address, uint withdrawalSum, bool dxt) onlyVoting external {
        lastWithdrawalTimestamp = block.timestamp;
        dxt ? _address.transfer(withdrawalSum) : DXT.transfer(_address, withdrawalSum);
    }

    function makeRefundableByUser() external {
        require(lastWithdrawalTimestamp != 0 && block.timestamp >= lastWithdrawalTimestamp + withdrawalPeriod);
        makeRefundable();
    }

    function makeRefundableByVotingDecision() external onlyVoting {
        makeRefundable();
    }

    function makeRefundable() private {
        require(!refundable);
        uint multiplier = 100000;
        refundable = true;
        newEtherRate = this.balance * etherRate * multiplier / tokenMintedByEther;
        newDXTRate = tokenMintedByDXT != 0 ? DXT.balanceOf(this) * DXTRate * multiplier / tokenMintedByDXT : 0;
    }

    function holdTokens(address _address, uint duration) onlyVoting external {
        token.hold(_address, duration);
    }

    modifier onlyVoting() {
        require(votings[msg.sender]);
        _;
    }
}
