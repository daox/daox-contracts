pragma solidity ^0.4.11;

import "./Token/Token.sol";
import "./DAO/DAOFactoryInterface.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract DAOx is Ownable {
    uint public balance;
    DAOFactoryInterface public daoFactory;

    function DAOx() {

    }

    function() payable onlyDAO {
        balance += msg.value;
    }

    function setDaoFactory(address _dao) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    function withdraw(uint _weiToWithdraw) public onlyOwner {
        balance -= _weiToWithdraw;
        msg.sender.transfer(_weiToWithdraw);
    }

    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }
}


