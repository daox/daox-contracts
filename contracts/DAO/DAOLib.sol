pragma solidity ^0.4.0;

import "../Token/TokenInterface.sol";
import "../Votings/VotingFactoryInterface.sol";
import '../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';

library DAOLib {
    event VotingCreated(
        address voting,
        string votingType,
        address dao,
		string name,
        string description,
        uint duration,
        address sender
    );

    /*
    * @dev Receives parameters from crowdsale module in case of successful crowdsale and processes them
    * @param token Instance of token contract
    * @param commissionRaised Amount of funds which were sent via commission contract
    * @param serviceContract Address of contract which receives commission
    * @param teamBonuses Array of percents which indicates the number of token for every team member
    * @param team Array of team members' addresses
    * @param teamHold Array of timestamp until which the tokens will be held for every team member
    * @return uint Amount of tokens minted for team
    */
    function handleFinishedCrowdsale(TokenInterface token, uint commissionRaised, address serviceContract, uint[] teamBonuses, address[] team, uint[] teamHold) returns (uint) {
        uint commission = (commissionRaised / 100) * 4;
        serviceContract.call.gas(200000).value(commission)();
        uint totalSupply = token.totalSupply() / 100;
        uint teamTokensAmount = 0;
        for (uint i = 0; i < team.length; i++) {
            uint teamMemberTokensAmount = SafeMath.mul(totalSupply, teamBonuses[i]);
            teamTokensAmount += teamMemberTokensAmount;
            token.mint(team[i], teamMemberTokensAmount);
            token.hold(team[i], teamHold[i]);
        }

        return teamTokensAmount;
    }

    function delegatedCreateRegular(VotingFactoryInterface _votingFactory, string _name, string _description, uint _duration, bytes32[] _options, address _dao) returns (address) {
        address _votingAddress = _votingFactory.createRegular(msg.sender, _name, _description, _duration, _options);
        VotingCreated(_votingAddress, "Regular", _dao, _name, _description, _duration, msg.sender);

        return _votingAddress;
    }

    function delegatedCreateWithdrawal(VotingFactoryInterface _votingFactory, string _name, string _description, uint _duration, uint _sum, address withdrawalWallet, bool _dxc, address _dao)
	returns (address)
	{
        address _votingAddress = _votingFactory.createWithdrawal(msg.sender, _name, _description, _duration, _sum, withdrawalWallet, _dxc);
        VotingCreated(_votingAddress, "Withdrawal", _dao, _name, _description, _duration, msg.sender);

        return _votingAddress;
    }

    function delegatedCreateRefund(VotingFactoryInterface _votingFactory, string _name, string _description, uint _duration, address _dao) returns (address) {
        address _votingAddress = _votingFactory.createRefund(msg.sender, _name, _description, _duration);
        VotingCreated(_votingAddress, "Refund", _dao, _name, _description, _duration, msg.sender);

        return _votingAddress;
    }

    function delegatedCreateModule(VotingFactoryInterface _votingFactory, string _name, string _description, uint _duration, uint _module, address _newAddress, address _dao) returns (address) {
        address _votingAddress = _votingFactory.createModule(msg.sender, _name, _description, _duration, _module, _newAddress);
        VotingCreated(_votingAddress, "Module", _dao, _name, _description, _duration, msg.sender);

        return _votingAddress;
    }

    /*
    * @dev Counts the number of tokens that should be minted according to amount of sent funds and current rate
    * @param value Amount of sent funds
    * @param bonusPeriods Array of timestamps indicating bonus periods
    * @param bonusRates Array of rates for every bonus period
    * @param rate Default rate
    * @return uint Amount of tokens that should be minted
    */
    function countTokens(uint value, uint[] bonusPeriods, uint[] bonusRates, uint rate) constant returns (uint) {
        if (bonusRates.length == 0) return value * rate; // DXC bonus rates could be empty

        for (uint i = 0; i < bonusPeriods.length; i++) {
            if (now < bonusPeriods[i]) {
                rate = bonusRates[i];
                break;
            }
        }
        uint tokensAmount = SafeMath.mul(value, rate);

        return tokensAmount;
    }

    /*
    * @dev Counts the amount of funds that must be returned to participant
    * @param tokensAmount Amount of tokens on participant's balance
    * @param etherRate Rate for ether during the crowdsale
    * @param newRate Current rate according to left funds and total supply of tokens
    * @param multiplier Multiplier that was used in previous calculations to avoid issues with float numbers
    * @return uint Amount of funds that must be returned to participant
    */
    function countRefundSum(uint tokensAmount, uint etherRate, uint newRate, uint multiplier) constant returns (uint) {
        uint fromPercentDivider = 100;

        return (tokensAmount * newRate / fromPercentDivider) / (multiplier * etherRate);
    }
}
