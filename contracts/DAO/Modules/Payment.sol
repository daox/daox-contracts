pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";
import "./OwnedFields.sol";

contract Payment is OwnedFields, CrowdsaleDAOFields {
    function getCommissionTokens() onlyParticipant succeededCrowdsale {
        require(addressesWithCommission[msg.sender] && depositedWei[msg.sender] > 0);
        delete addressesWithCommission[msg.sender];
        assert(!serviceContract.call(bytes4(keccak256("getCommissionTokens(address,uint)")), msg.sender, depositedWei[msg.sender]));
    }

    function refund() whenRefundable {
        require(teamBonuses[msg.sender] == 0);

        token.burn(msg.sender);
        assert(!msg.sender.call.value(DAOLib.countRefundSum(token, rate, newRate)*1 wei)());
    }

    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0);

        token.burn(msg.sender);
        delete depositedWei[msg.sender];
        assert(!msg.sender.call.value(depositedWei[msg.sender])());
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
        require(participants[msg.sender]);
        _;
    }

    modifier succeededCrowdsale() {
        require(crowdsaleFinished && weiRaised >= softCap);
        _;
    }
}
