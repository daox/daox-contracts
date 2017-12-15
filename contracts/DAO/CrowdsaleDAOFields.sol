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
    bool internal canInitCrowdsaleParameters = true;
    uint public commissionRaised = 0;
    uint public weiRaised = 0;
    mapping(address => uint) public depositedWei;
    mapping(address => bool) public addressesWithCommission;
    bool crowdsaleFinished;
    bool public refundableSoftCap = false;
    uint newRate = 0;
    address serviceContract;
    uint[] teamBonusesArr;
    address[] team;
    uint tokenHoldTime = 0;
    TokenInterface public token;
    VotingFactoryInterface public votingFactory;
    UserInterface public users;
    address public commissionContract;
    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint public minVote; // in percents
    mapping(address => bool) public votings;
    uint public participantsCount = 1;
    address parentAddress;
}
