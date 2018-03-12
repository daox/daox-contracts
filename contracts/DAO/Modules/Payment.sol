pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";

contract Payment is CrowdsaleDAOFields {
    function getCommissionTokens() onlyParticipant succeededCrowdsale {
        require(depositedWithCommission[msg.sender] > 0);
        uint depositedWithCommissionAmount = depositedWithCommission[msg.sender];
        delete depositedWithCommission[msg.sender];
        assert(serviceContract.call(bytes4(keccak256("getCommissionTokens(address,uint256)")), msg.sender, depositedWithCommissionAmount));
    }

    function refund() whenRefundable {
        require(teamBonuses[msg.sender] == 0);
        uint multiplier = 100;

        uint etherPerDXTRate = tokenMintedByEther * multiplier / (tokenMintedByEther + tokenMintedByDXT);
        uint dxtPerEtherRate = tokenMintedByDXT * multiplier / (tokenMintedByEther + tokenMintedByDXT);

        uint tokensAmount = token.balanceOf(msg.sender);
        token.burn(msg.sender);

        if (etherPerDXTRate != 0)
            msg.sender.transfer(DAOLib.countRefundSum(etherPerDXTRate * tokensAmount, etherRate, newEtherRate));

        if (dxtPerEtherRate != 0)
            DXT.transfer(msg.sender, DAOLib.countRefundSum(dxtPerEtherRate * tokensAmount, DXTRate, newDXTRate));
    }

    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0);

        token.burn(msg.sender);
        uint weiAmount = depositedWei[msg.sender];
        uint tokensAmount = depositedDXT[msg.sender];

        delete depositedWei[msg.sender];
        delete depositedWithCommission[msg.sender];
        delete depositedDXT[msg.sender];

        DXT.transfer(msg.sender, tokensAmount);
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
