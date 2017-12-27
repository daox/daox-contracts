pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";

contract Payment is CrowdsaleDAOFields {
    function getCommissionTokens() onlyParticipant succeededCrowdsale {
        require(addressesWithCommission[msg.sender] && depositedWei[msg.sender] > 0);
        delete addressesWithCommission[msg.sender];
        assert(!serviceContract.call(bytes4(keccak256("getCommissionTokens(address,uint)")), msg.sender, depositedWei[msg.sender]));
    }

    function refund() whenRefundable {
        require(teamBonuses[msg.sender] == 0);

        token.burn(msg.sender);
        msg.sender.transfer(DAOLib.countRefundSum(token, rate, newRate)*1 wei);
    }

    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0);

        token.burn(msg.sender);
        uint weiAmount = depositedWei[msg.sender];
        delete depositedWei[msg.sender];
        msg.sender.transfer(weiAmount);
    }

    modifier whenRefundable() {
        require(refundable);
        _;
    }

    modifier whenRefundableSoftCap() {
        require(refundableSoftCap);
        _;
    }

    modifier onlyParticipant {
        require(token.balanceOf(msg.sender) > 0);
        _;
    }

    modifier succeededCrowdsale() {
        require(crowdsaleFinished && weiRaised >= softCap);
        _;
    }
}
