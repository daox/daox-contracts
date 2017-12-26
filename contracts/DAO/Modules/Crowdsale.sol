pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "../Owned.sol";

contract Crowdsale is CrowdsaleDAOFields {
    address public owner;

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) onlyOwner(msg.sender) canInit {
        require(_softCap != 0 && _hardCap != 0 && _rate != 0 && _startBlock != 0 && _endBlock != 0);
        require(_softCap < _hardCap && _startBlock > block.number);
        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;

        canInitCrowdsaleParameters = false;
    }

    function finish() {
        require(block.number >= endBlock && !crowdsaleFinished);

        crowdsaleFinished = true;

        if(weiRaised >= softCap) DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, tokenHoldTime);
        else {
            refundableSoftCap = true;
            newRate = rate;
        }

        token.finishMinting();
    }

    function handlePayment(address _sender, bool commission) payable CrowdsaleStarted validPurchase(msg.value) external {
        require(_sender != 0x0);

        uint weiAmount = msg.value;
        if(commission) {
            commissionRaised = commissionRaised + weiAmount;
            addressesWithCommission[_sender] = true;
        }

        weiRaised = weiRaised + weiAmount;
        depositedWei[_sender] = depositedWei[_sender] + weiAmount;

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
        require(block.number >= startBlock);
        _;
    }

    modifier validPurchase(uint value) {
        require(weiRaised + value < hardCap && block.number < endBlock);
        _;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }
}