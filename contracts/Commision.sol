pragma solidity ^0.4.11;

interface IDAOPayable {
    function handlePayment(bool commission) payable;
}

contract Commission {
    IDAOPayable dao;

    function Commission(address _dao) {
        dao = IDAOPayable(_dao);
    }

    function() payable {
        dao.handlePayment.value(msg.value)(msg.sender, true);
    }
}
