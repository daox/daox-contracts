pragma solidity ^0.4.11;

import "./Token/Token.sol";

contract DAOx {

    Token public token;
    uint public constant tokenRate = 100;
    uint weiRaised;

    function DAOx(address daoFactoryAddress){
        token = new Token("DAOx", "DAOX");
    }

    function() payable onlyDAO {
        uint weiAmount = msg.value;

        uint tokensAmount = weiAmount * tokenRate;

        // update state
        weiRaised = weiRaised + weiAmount;

        token.mint(msg.sender, tokensAmount);

        //forwardFunds();
    }
}
