pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "../Owned.sol";

contract Crowdsale is CrowdsaleDAOFields {
	address public owner;

	function handlePayment(address _sender, bool commission) external payable CrowdsaleStarted validEtherPurchase(msg.value) {
		require(_sender != 0x0);

		uint weiAmount = msg.value;
		if (commission) {
				commissionRaised = commissionRaised + weiAmount;
				depositedWithCommission[_sender] += weiAmount;
		}

		weiRaised += weiAmount;
		depositedWei[_sender] += weiAmount;

		uint tokensAmount = DAOLib.countTokens(weiAmount, bonusPeriods, bonusEtherRates, etherRate);
		tokenMintedByEther += tokensAmount;
		token.mint(_sender, tokensAmount);
	}

	function handleDXTPayment(address _sender, uint dxtAmount) external CrowdsaleStarted validDXTPurchase(dxtAmount) {
		require(_sender != 0x0);

		DXTRaised += dxtAmount;
		depositedDXT[_sender] += dxtAmount;

		uint tokensAmount = DAOLib.countTokens(dxtAmount, bonusPeriods, bonusDXTRates, DXTRate);
		tokenMintedByDXT += tokensAmount;
		token.mint(_sender, tokensAmount);
	}

	function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _startTime, uint _endTime) external onlyOwner(msg.sender) canInit {
			require(_softCap != 0 && _hardCap != 0 && _etherRate != 0 && _startTime != 0 && _endTime != 0);
			require(_softCap < _hardCap && _startTime > block.timestamp);
			softCap = _softCap * 1 ether;
			hardCap = _hardCap * 1 ether;

			startTime = _startTime;
			endTime = _endTime;

			etherRate = _etherRate;

			canInitCrowdsaleParameters = false;
	}

	function finish() external {
			require((block.timestamp >= endTime || weiRaised == hardCap) && !crowdsaleFinished);

			crowdsaleFinished = true;

			if(weiRaised >= softCap) {
				teamTokensAmount = DAOLib.handleFinishedCrowdsale(token, commissionRaised, serviceContract, teamBonusesArr, team, teamHold);
			} else {
				refundableSoftCap = true;
			}

			token.finishMinting();
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
			require(block.timestamp >= startTime && block.timestamp < endTime && !crowdsaleFinished);
			_;
	}

	modifier validEtherPurchase(uint value) {
			require(weiRaised + value <= hardCap);
			_;
	}

	modifier validDXTPurchase(uint value) {
		require(weiRaised + value / (etherRate / DXTRate) <= hardCap);
		_;
	}


	modifier onlyOwner(address _sender) {
			require(_sender == owner);
			_;
	}
}