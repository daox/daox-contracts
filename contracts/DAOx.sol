pragma solidity ^0.4.11;

import "./Token/Token.sol";
import "./DAO/DAOFactoryInterface.sol";
import "./DAO/Owned.sol";

contract DAOx is Owned {
    Token public token;
    uint public constant tokenRate = 100;
    uint weiRaised;
    DAOFactoryInterface daoFactory;

    function DAOx() Owned(msg.sender){
        token = new Token("DAOx", "DAOX");
    }

    function() payable onlyDAO {
        weiRaised = weiRaised + msg.value;
    }

    function setDaoFactory(address _dao, address _creator) external onlyOwner(_creator) {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    function getCommissionTokens(address _address, uint weiSent) external onlyDAO {
        uint tokensAmount = weiSent * tokenRate;
        token.mint(_address, tokensAmount);
    }

    function withdraw(uint sum) onlyOwner(msg.sender) {
        assert(owner.call.value(sum*1 wei)());
    }

    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }
}


