pragma solidity ^0.4.0;

import "./CrowdsaleDAOFields.sol";
import "./DAOLib.sol";
import "../Commission.sol";
import "../Token/TokenInterface.sol";
import "../Users/UserInterface.sol";
import "../Votings/VotingFactoryInterface.sol";

contract CrowdsaleDAOProxy is CrowdsaleDAOFields {

    function create(address _usersAddress, uint8 _minVote, address _tokenAddress, address _votingFactory, address _serviceContract, address _ownerAddress, address _parentAddress) {
        users = UserInterface(_usersAddress);
        token = TokenInterface(_tokenAddress);
        votingFactory = VotingFactoryInterface(_votingFactory);
        minVote = _minVote;
        participants[_ownerAddress] = true;
        created_at = block.timestamp;

        serviceContract = _serviceContract;
        commissionContract = new Commission(this);
        parentAddress = _parentAddress;
    }

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) external {
        require(block.number < _startBlock && _softCap < _hardCap && _softCap != 0 && _rate != 0);
        softCap = _softCap * 1 ether;
        hardCap = _hardCap * 1 ether;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;

        canInitCrowdsaleParameters = false;
    }

    function handlePayment(address _sender, bool commission) external {
        uint weiAmount = msg.value;
        if(commission) {
            commissionRaised = commissionRaised + weiAmount;
            addressesWithCommission[_sender] = true;
        }

        weiRaised = weiRaised + weiAmount;
        depositedWei[_sender] = depositedWei[_sender] + weiAmount;
    }

    function finish() {
        isCrowdsaleFinished = true;

        if(weiRaised >= softCap) DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, tokenHoldTime);
        else {
            refundableSoftCap = true;
            newRate = rate;
        }

        token.finishMinting();
    }
}
