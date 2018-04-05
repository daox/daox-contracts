pragma solidity ^0.4.0;

import "../DAOLib.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "../Owned.sol";

contract Crowdsale is CrowdsaleDAOFields {
	address public owner;

	function handlePayment(address _sender, bool commission) external payable CrowdsaleIsOngoing validEtherPurchase(msg.value) {
		require(_sender != 0x0);

		uint weiAmount = msg.value;
		if (commission) {
			commissionRaised = commissionRaised + weiAmount;
		}

		weiRaised += weiAmount;
		depositedWei[_sender] += weiAmount;

		uint tokensAmount = DAOLib.countTokens(weiAmount, bonusPeriods, bonusEtherRates, etherRate);
		tokensMintedByEther += tokensAmount;
		token.mint(_sender, tokensAmount);
	}

	function handleDXCPayment(address _from, uint _dxcAmount) external CrowdsaleIsOngoing validDXCPurchase(_dxcAmount) onlyDXC {
		DXCRaised += _dxcAmount;
		depositedDXC[_from] += _dxcAmount;

		uint tokensAmount = DAOLib.countTokens(_dxcAmount, bonusPeriods, bonusDXCRates, DXCRate);
		tokensMintedByDXC += tokensAmount;

		token.mint(_from, tokensAmount);
	}

	function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _DXCRate, uint _startTime, uint _endTime, bool _dxcPayments)
	external
	onlyOwner(msg.sender)
	canInit
	{
		require(_softCap != 0 && _hardCap != 0 && _etherRate != 0 && _DXCRate != 0 && _startTime != 0 && _endTime != 0);
		require(_softCap < _hardCap && _startTime > block.timestamp);

		softCap = _softCap * 1 ether;
		hardCap = _hardCap * 1 ether;

		(startTime, endTime) = (_startTime, _endTime);

		(dxcPayments, etherRate, DXCRate) = (_dxcPayments, _etherRate, _DXCRate);

		canInitCrowdsaleParameters = false;
	}

	function finish() external {
		fundsRaised = DXCRate != 0 ? weiRaised + (DXC.balanceOf(this)) / (etherRate / DXCRate) : weiRaised;

		require((block.timestamp >= endTime || fundsRaised == hardCap) && !crowdsaleFinished);

		crowdsaleFinished = true;

		if (fundsRaised >= softCap) {
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

	modifier CrowdsaleIsOngoing() {
		require(block.timestamp >= startTime && block.timestamp < endTime && !crowdsaleFinished);
		_;
	}

	modifier validEtherPurchase(uint value) {
		require(DXCRate != 0 ?
			hardCap - DXCRaised / (etherRate / DXCRate) >= weiRaised + value :
			hardCap >= weiRaised + value);
		_;
	}

	modifier validDXCPurchase(uint value) {
		require(dxcPayments && (hardCap - weiRaised >= (value + DXCRaised) / (etherRate / DXCRate)));
		_;
	}

	modifier onlyDXC() {
		require(msg.sender == address(DXC));
		_;
	}

	modifier onlyOwner(address _sender) {
		require(_sender == owner);
		_;
	}
}