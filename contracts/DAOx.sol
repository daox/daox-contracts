pragma solidity ^0.4.11;

import "./Token/Token.sol";
import "./DAO/DAOFactoryInterface.sol";

contract Owned {
    address owner;

    function Owned(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract DAOx is Owned {
    Token public token;
    uint public constant tokenRate = 100;
    uint weiRaised;
    DAOFactoryInterface daoFactory;

    function DAOx(){
        token = new Token("DAOx", "DAOX");
    }

    function() onlyDAO payable {
        weiRaised = weiRaised + msg.value;
    }

    function setDaoFactory(address _dao) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    function getCommissionTokens(address _address, uint weiSent) onlyDAO external {
        uint tokensAmount = weiSent * tokenRate;
        token.mint(msg.sender, tokensAmount);
    }

    function withdraw(uint sum) onlyOwner {
        assert(!owner.call.value(sum*1 wei)());
    }

    modifier onlyDAO() {
        require(dao.exists(msg.sender));
        _;
    }
}


