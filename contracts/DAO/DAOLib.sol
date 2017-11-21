pragma solidity ^0.4.0;

import "../Token/TokenInterface";

library DAOLib {
    function countTokens(TokenInterface token, uint weiAmount, uint[] bonusPeriods, uint[] bonusRates) constant returns (uint) {
        uint tokenRate = rate;
        for(uint i = 0; i < bonusPeriods.length; i++) {
            if(now < bonusPeriods[i]) tokenRate = bonusRates[i];
        }
        uint tokenAmount = weiAmount * tokenRate;
        token.mint(_sender, tokensAmount);

        return tokenAmount;
    }

    function countRefundSum(TokenInterface token, uint rate, uint newRate) constant returns (uint) {
        uint multiplier = 1000;
        uint newRateToOld = newRate*multiplier / rate;
        uint weiSpent = token.balanceOf(msg.sender) / rate;
        return weiSpent*multiplier / newRateToOld;
    }

    function handleFinishedCrowdsale(TokenInterface token, uint commissionRaised, address serviceContract, address[] team, uint[] teamBonuses) {
        uint commission = (commissionRaised/100)*4;
        assert(!serviceContract.call.value(commission*1 wei)());
        for(uint i = 0; i < team.length; i++) {
            token.mint(team[i], (token.totalSupply()/100)*teamBonuses[i]);
        }
    }
}
