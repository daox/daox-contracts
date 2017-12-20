pragma solidity ^0.4.0;

import "../Token/TokenInterface.sol";
import "../Users/UserInterface.sol";
import "../Votings/VotingFactoryInterface.sol";

contract CrowdsaleDAOFields {
    uint public rate;
    uint public softCap;
    uint public hardCap;
    uint public startBlock;
    uint public endBlock;
    bool public canInitCrowdsaleParameters = true;
    uint public commissionRaised = 0;
    uint public weiRaised = 0;
    mapping(address => uint) public depositedWei;
    mapping(address => bool) public addressesWithCommission;
    bool public crowdsaleFinished;
    bool public refundableSoftCap = false;
    uint newRate = 0;
    address serviceContract;
    uint[] teamBonusesArr;
    address[] team;
    uint public tokenHoldTime = 0;
    TokenInterface public token;
    VotingFactoryInterface public votingFactory;
    address public commissionContract;
    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint public minVote; // in percents
    mapping(address => bool) public votings;
    uint public participantsCount = 1;
    bool public refundable = false;
    uint internal lastWithdrawalTimestamp = 0;
    uint constant internal withdrawalPeriod = 120 * 24 * 60 * 60;
    address[] whiteListArr;
    mapping(address => bool) whiteList;
    mapping(address => uint) public teamBonuses;
    uint[] bonusPeriods;
    uint[] bonusRates;
}
