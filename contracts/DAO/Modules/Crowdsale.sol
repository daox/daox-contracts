pragma solidity ^0.4.0;

import "../Owned.sol";
import "../DAOLib.sol";

contract Crowdsale is Owned {
    uint softCap;
    uint hardCap;
    uint startBlock;
    uint endBlock;
    uint rate;
    bool canInitCrowdsaleParameters;
    address commissionContract;
    bool refundableSoftCap;
    bool crowdsaleFinished;
    uint weiRaised;
    uint commissionRaised;
    mapping(address => bool) public addressesWithCommission;
    mapping(address => uint) public depositedWei;
    TokenInterface public token;
    address serviceContract;
    uint[] teamBonusesArr;
    address[] team;
    uint tokenHoldTime = 0;
    uint newRate = 0;

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) onlyOwner canInit(canInitCrowdsaleParameters) {
        require(block.number < _startBlock && _softCap < _hardCap && _softCap != 0 && _rate != 0);

        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;

        canInitCrowdsaleParameters = false;
    }

    function finish() onlyOwner {
        require(block.number >= endBlock);

        crowdsaleFinished = true;

        if(weiRaised >= softCap) DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, tokenHoldTime);
        else {
            refundableSoftCap = true;
            newRate = rate;
        }

        token.finishMinting();
    }

    function handlePayment(address _sender, bool commission) CrowdsaleStarted validPurchase(msg.value) external {
        require(_sender != 0x0);

        uint weiAmount = msg.value;
        if(commission) {
            commissionRaised = commissionRaised + weiAmount;
            addressesWithCommission[_sender] = true;
        }

        weiRaised = weiRaised + weiAmount;
        depositedWei[_sender] = depositedWei[_sender] + weiAmount;
    }

    modifier canInit(bool permission) {
        require(permission);
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
}
