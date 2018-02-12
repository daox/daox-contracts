pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "../Owned.sol";

contract Crowdsale is CrowdsaleDAOFields {
    address public owner;

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startTime, uint _endTime) onlyOwner(msg.sender) canInit {
        require(_softCap != 0 && _hardCap != 0 && _rate != 0 && _startTime != 0 && _endTime != 0);
        require(_softCap < _hardCap && _startTime > block.timestamp);
        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startTime = _startTime;
        endTime = _endTime;

        rate = _rate;

        canInitCrowdsaleParameters = false;
    }

    function finish() {
        require(block.timestamp >= endTime && !crowdsaleFinished);

        crowdsaleFinished = true;
        newRate = rate;

        if(weiRaised >= softCap) {
            teamTokensAmount = DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, teamHold);
        } else {
            refundableSoftCap = true;
        }

        token.finishMinting();
    }

    function handlePayment(address _sender, bool commission) payable CrowdsaleStarted validPurchase(msg.value) external {
        require(_sender != 0x0);

        uint weiAmount = msg.value;
        if(commission) {
            commissionRaised = commissionRaised + weiAmount;
            depositedWithCommission[_sender] += weiAmount;
        }

        weiRaised += weiAmount;
        depositedWei[_sender] += weiAmount;

        uint tokensAmount = DAOLib.countTokens(weiAmount, bonusPeriods, bonusRates, rate);
        token.mint(_sender, tokensAmount);
    }

    modifier canInit() {
        require(canInitCrowdsaleParameters);
        _;
    }

    modifier onlyCommission() {
        require(commissionContract == msg.sender);
        _;
    }

    modifier CrowdsaleStarted() {
        require(block.timestamp >= startTime);
        _;
    }

    modifier validPurchase(uint value) {
        require(weiRaised + value <= hardCap && block.timestamp < endTime);
        _;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }
}