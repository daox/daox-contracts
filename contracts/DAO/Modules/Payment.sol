pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";

contract Payment is CrowdsaleDAOFields {
    function refund() whenRefundable notTeamMember {
        uint etherPerDXCRate = tokensMintedByEther * percentMultiplier / (tokensMintedByEther + tokensMintedByDXC);
        uint dxcPerEtherRate = tokensMintedByDXC * percentMultiplier / (tokensMintedByEther + tokensMintedByDXC);

        uint tokensAmount = token.balanceOf(msg.sender);
        token.burn(msg.sender);

        if (etherPerDXCRate != 0)
            msg.sender.transfer(DAOLib.countRefundSum(etherPerDXCRate * tokensAmount, etherRate, newEtherRate, multiplier));

        if (dxcPerEtherRate != 0)
            DXC.transfer(msg.sender, DAOLib.countRefundSum(dxcPerEtherRate * tokensAmount, DXCRate, newDXCRate, multiplier));
    }

    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0 || depositedDXC[msg.sender] != 0);

        token.burn(msg.sender);
        uint weiAmount = depositedWei[msg.sender];
        uint tokensAmount = depositedDXC[msg.sender];

        delete depositedWei[msg.sender];
        delete depositedWithCommission[msg.sender];
        delete depositedDXC[msg.sender];

        DXC.transfer(msg.sender, tokensAmount);
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

    modifier notTeamMember() {
        require(teamBonuses[msg.sender] == 0);
        _;
    }
}
