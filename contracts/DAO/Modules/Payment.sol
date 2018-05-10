pragma solidity ^0.4.0;

import '../../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";

contract Payment is CrowdsaleDAOFields {
    /*
    * @dev Returns funds to participant according to amount of funds that left in DAO and amount of tokens for this participant
    */
    function refund() whenRefundable notTeamMember {
        uint tokensMintedSum = SafeMath.add(tokensMintedByEther, tokensMintedByDXC);
        uint etherPerDXCRate = SafeMath.mul(tokensMintedByEther, percentMultiplier) / tokensMintedSum;
        uint dxcPerEtherRate = SafeMath.mul(tokensMintedByDXC, percentMultiplier) / tokensMintedSum;

        uint tokensAmount = token.balanceOf(msg.sender);
        token.burn(msg.sender);

        if (etherPerDXCRate != 0)
            msg.sender.transfer(DAOLib.countRefundSum(etherPerDXCRate * tokensAmount, etherRate, newEtherRate, multiplier));

        if (dxcPerEtherRate != 0)
            DXC.transfer(msg.sender, DAOLib.countRefundSum(dxcPerEtherRate * tokensAmount, DXCRate, newDXCRate, multiplier));
    }

    /*
    * @dev Returns funds which were sent to crowdsale contract back to backer and burns tokens that were minted for him
    */
    function refundSoftCap() whenRefundableSoftCap {
        require(depositedWei[msg.sender] != 0 || depositedDXC[msg.sender] != 0);

        token.burn(msg.sender);
        uint weiAmount = depositedWei[msg.sender];
        uint tokensAmount = depositedDXC[msg.sender];

        delete depositedWei[msg.sender];
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

    modifier notTeamMember() {
        require(!teamMap[msg.sender]);
        _;
    }
}
