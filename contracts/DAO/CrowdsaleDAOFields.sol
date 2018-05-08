pragma solidity ^0.4.0;

import "../Token/TokenInterface.sol";
import "../Votings/VotingFactoryInterface.sol";

contract CrowdsaleDAOFields {
    uint public etherRate;
    uint public DXCRate;
    uint public softCap;
    uint public hardCap;
    uint public startTime;
    uint public endTime;
    bool public canInitCrowdsaleParameters = true;
    bool public canInitStateParameters = true;
    bool public canInitBonuses = true;
    bool public canSetWhiteList = true;
    uint public commissionRaised = 0; // Funds that was provided via commission contract
    uint public weiRaised = 0;
    uint public DXCRaised = 0;
    uint public fundsRaised = 0;
    mapping(address => uint) public depositedWei; // Used for refund in case of not reached soft cap
    mapping(address => uint) public depositedDXC; // Used for refund in case of not reached soft cap
    bool public crowdsaleFinished;
    bool public refundableSoftCap = false;
    uint public newEtherRate = 0; // Used for refund after accept of Refund proposal
    uint public newDXCRate = 0; // Used for refund after accept of Refund proposal
    address public serviceContract; //Contract which gets commission funds if soft cap was reached during the crowdsale
    uint[] public teamBonusesArr;
    address[] public team;
    mapping(address => bool) public teamMap;
    uint[] public teamHold;
    bool[] public teamServiceMember;
    TokenInterface public token;
    VotingFactoryInterface public votingFactory;
    address public commissionContract; //Contract that is used to mark funds which were provided through daox.org platform
    string public name;
	string public description;
    uint public created_at = now; // UNIX time
    mapping(address => bool) public votings;
    bool public refundable = false;
    uint public lastWithdrawalTimestamp = 0;
    address[] public whiteListArr;
    mapping(address => bool) public whiteList;
    mapping(address => uint) public teamBonuses;
    uint[] public bonusPeriods;
    uint[] public bonusEtherRates;
    uint[] public bonusDXCRates;
    uint public teamTokensAmount;
    uint constant internal withdrawalPeriod = 120 * 24 * 60 * 60;
    TokenInterface public DXC;
    uint public tokensMintedByEther;
    uint public tokensMintedByDXC;
    bool public dxcPayments; //Flag indicating whether it is possible to invest via DXC token or not
    uint internal constant multiplier = 100000;
    uint internal constant percentMultiplier = 100;
}
