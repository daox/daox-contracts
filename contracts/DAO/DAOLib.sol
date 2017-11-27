pragma solidity ^0.4.0;

import "../Token/TokenInterface.sol";

library DAOLib {
    function countTokens(TokenInterface token, uint weiAmount, uint[] bonusPeriods, uint[] bonusRates, uint rate, address _sender) constant returns (uint) {
        uint tokenRate = rate;
        for(uint i = 0; i < bonusPeriods.length; i++) {
            if(now < bonusPeriods[i]) tokenRate = bonusRates[i];
        }
        uint tokensAmount = weiAmount * tokenRate;
        token.mint(_sender, tokensAmount);

        return tokensAmount;
    }

    function countRefundSum(TokenInterface token, uint rate, uint newRate) constant returns (uint) {
        uint multiplier = 1000;
        uint newRateToOld = newRate*multiplier / rate;
        uint weiSpent = token.balanceOf(msg.sender) / rate;
        return weiSpent*multiplier / newRateToOld;
    }

    function handleFinishedCrowdsale(TokenInterface token, uint commissionRaised, address serviceContract, uint[] teamBonuses, address[] team) {
        uint commission = (commissionRaised/100)*4;
        assert(!serviceContract.call.value(commission*1 wei)());
        for(uint i = 0; i < team.length; i++) {
            token.mint(team[i], (token.totalSupply()/100)*teamBonuses[i]);
        }
    }

    function delegateIsParticipant(address _parentAddress, address _participantAddress) constant returns (bool) {
        _parentAddress.delegatecall(bytes4(keccak256("isParticipant(address)")), _participantAddress);
    }

    function delegateAddParticipant(address _parentAddress, address _participantAddress) {
        _parentAddress.delegatecall(bytes4(keccak256("addParticipant(address)")), _participantAddress);
    }

    function delegateRemove(address _parentAddress, address _participantAddress) {
        _parentAddress.delegatecall(bytes4(keccak256("remove(address)")), _participantAddress);
    }

    //ToDo: finish proposal creating functions
    function delegatedCreateProposal(address _votingFactory, string _description, uint _duration, bytes32[] _options) {
        _votingFactory.delegatecall(bytes4(keccak256("createProposal(address,string,uint256,bytes32[]")), msg.sender, _description, _duration, _options);
    }

    function delegatedCreateWithdrawal(address _votingFactory, string _description, uint _duration, uint _sum) {
        _votingFactory.delegatecall(bytes4(keccak256("createWithdrawal(address,string,uint256,uint256)")), msg.sender, _description, _duration, _sum);
    }

    function delegatedCreateRefund(address _votingFactory, string _description, uint _duration) {
        _votingFactory.delegatecall(bytes4(keccak256("createRefund(address,string,uint256)")), msg.sender, _description, _duration);
    }
}
