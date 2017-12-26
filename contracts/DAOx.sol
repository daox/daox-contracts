pragma solidity ^0.4.11;

import "./Token/Token.sol";
import "./DAO/DAOFactoryInterface.sol";
import "./DAO/Owned.sol";

contract DAOx is Owned {
    Token public token;
    uint public constant tokenRate = 100;
    uint weiRaised;
    DAOFactoryInterface daoFactory;

    function DAOx()
    Owned(msg.sender){
        token = new Token("DAOx", "DAOX");
    }

    function() onlyDAO payable {
        weiRaised = weiRaised + msg.value;
    }

    function setDaoFactory(address _dao, address _creator) onlyOwner(_creator) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    function getCommissionTokens(address _address, uint weiSent) onlyDAO external {
        uint tokensAmount = weiSent * tokenRate;
        token.mint(msg.sender, tokensAmount);
    }

    function withdraw(uint sum) onlyOwner(msg.sender) {
        assert(!owner.call.value(sum*1 wei)());
    }

    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }
}


