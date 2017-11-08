pragma solidity ^0.4.11;

import "./Token.sol";

contract CrowdsaleDAO is DAO {
    Token public token;
    uint public rate;

    function() payable {
        require(msg.sender != 0x0);
        require(validPurchase());
        uint weiAmount = msg.value;

        uint tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function createTokens(string name, string symbol, uint decimals) {
        address _token = new Token(name, symbol, decimals);
        token = Token(_token);
    }
}
