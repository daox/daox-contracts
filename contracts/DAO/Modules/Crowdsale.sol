pragma solidity ^0.4.0;

import '../../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import "../DAOLib.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "../Owned.sol";

contract Crowdsale is CrowdsaleDAOFields {
	address public owner;

	/*
    * @dev Receives info about ether payment from CrowdsaleDAO contract then mints tokens for sender and saves info about
    *      sent funds to either return it in case of refund or get commission from them in case of successful crowdsale
    * @param _sender Address of sender
    * @param _commission Boolean indicating whether it is needed to take commission from sent funds or not
    */
	function handlePayment(address _sender, bool _commission) external payable CrowdsaleIsOngoing validEtherPurchase(msg.value) {
		require(_sender != 0x0);

		uint weiAmount = msg.value;
		if (_commission) {
			commissionRaised = commissionRaised + weiAmount;
		}

		weiRaised += weiAmount;
		depositedWei[_sender] += weiAmount;

		uint tokensAmount = DAOLib.countTokens(weiAmount, bonusPeriods, bonusEtherRates, etherRate);
		tokensMintedByEther = SafeMath.add(tokensMintedByEther, tokensAmount);
		token.mint(_sender, tokensAmount);

		if(lockup > 0) token.hold(_sender, lockup - now);
	}

	/*
    * @dev Receives info about DXC payment from CrowdsaleDAO contract then mints tokens for sender and saves info about
    *      sent funds to return it in case of refund
    * @param _from Address of sender
    * @param _dxcAmount Amount of DXC token which were sent to DAO
    */
	function handleDXCPayment(address _from, uint _dxcAmount) external CrowdsaleIsOngoing validDXCPurchase(_dxcAmount) onlyDXC {
		DXCRaised += _dxcAmount;
		depositedDXC[_from] += _dxcAmount;

		uint tokensAmount = DAOLib.countTokens(_dxcAmount, bonusPeriods, bonusDXCRates, DXCRate);
		tokensMintedByDXC = SafeMath.add(tokensMintedByDXC, tokensAmount);
		token.mint(_from, tokensAmount);

		if(lockup > 0) token.hold(_from, lockup - now);
	}

	/*
    * @dev Sets main parameters for upcoming crowdsale
    * @param _softCap The minimal amount of funds that must be collected by DAO for crowdsale to be considered successful
    * @param _hardCap The maximal amount of funds that can be raised during the crowdsale
    * @param _etherRate Amount of tokens that will be minted per one ether
    * @param _DXCRate Amount of tokens that will be minted per one DXC
    * @param _startTime Unix timestamp that indicates the moment when crowdsale will start
    * @param _endTime Unix timestamp which indicates the moment when crowdsale will end
    * @param _dxcPayments Boolean indicating whether it is possible to invest via DXC token or not
    */
	function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _etherRate, uint _DXCRate, uint _startTime, uint _endTime, bool _dxcPayments, uint _lockup)
		external
		onlyOwner(msg.sender)
		canInit
	{
		require(_softCap != 0 && _hardCap != 0 && _etherRate != 0 && _DXCRate != 0 && _startTime != 0 && _endTime != 0);
		require(_softCap < _hardCap && _startTime > block.timestamp);
		require(_lockup == 0 || _lockup > _endTime);

		softCap = _softCap * 1 ether;
		hardCap = _hardCap * 1 ether;

		(startTime, endTime, lockup) = (_startTime, _endTime, _lockup);

		(dxcPayments, etherRate, DXCRate) = (_dxcPayments, _etherRate, _DXCRate);

		canInitCrowdsaleParameters = false;
	}

	/*
    * @dev Finishes the crowdsale and analyzes whether it is successful or not. If it is not then DAO goes to refundableSoftCap
    *      state otherwise it counts and mints tokens for team members and holds them for certain period of time according to
    *      parameters which were set for every member via initBonuses function. In addition function sends commission to service contract
    */
	function finish() external {
		fundsRaised = DXCRate != 0 ? weiRaised + (DXCRaised) / (etherRate / DXCRate) : weiRaised;

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