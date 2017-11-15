pragma solidity ^0.4.11;

import "./DAO/DAOFactoryInterface.sol";
import "../Token/Token.sol";

contract DAOx {

    DAOFactoryInterface public DAOFactory;
    Token public token;
    uint public constant tokenRate = 100;
    uint weiAmount;

    function DAOx(address daoFactoryAddress){
        token = new Token("DAOx", "DAOX", 18);
        DAOFactory = DAOFactoryInterface(daoFactoryAddress);
    }

    function() payable onlyDAO {
        uint weiAmount = msg.value;

        uint tokensAmount = weiAmount * tokenRate;

        // update state
        weiRaised = weiRaised + weiAmount;

        token.mint(msg.sender, tokensAmount);

        //forwardFunds();
    }

    modifier onlyDAO {
        require(DAOFactory.exists(msg.sender));
        _;
    }
}
