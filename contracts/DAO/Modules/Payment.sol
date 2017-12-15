pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";

contract Payment {
    uint public rate;
    uint newRate = 0;
    uint public softCap;
    bool crowdsaleFinished;
    address serviceContract;
    uint public weiRaised = 0;
    TokenInterface public token;
    bool public refundable = false;
    bool public refundableSoftCap = false;
    mapping(address => uint) public teamBonuses;
    mapping(address => uint) public depositedWei;
    mapping (address => bool) public participants;
    mapping(address => bool) public addressesWithCommission;

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
