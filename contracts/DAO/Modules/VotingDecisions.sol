pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";

contract VotingDecisions is CrowdsaleDAOFields {

    function withdrawal(address _address, uint withdrawalSum) onlyVoting external {
        assert(_address.call.value(withdrawalSum * 1 ether)());
        lastWithdrawalTimestamp = block.timestamp;
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
        refundable = true;
        newRate = token.totalSupply() / this.balance;
    }

    function holdTokens(address _address, uint duration) onlyVoting external {
        token.hold(_address, duration);
    }

    function flushWhiteList() onlyVoting external {
        for(uint i = 0; i < whiteListArr.length; i++) {
            delete whiteList[whiteListArr[i]];
        }
    }

    function changeWhiteList(address _addr, bool res) onlyVoting external {
        if(!res) delete whiteList[_addr];
        whiteList[_addr] = true;
    }

    modifier onlyVoting() {
        require(votings[msg.sender]);
        _;
    }
}
