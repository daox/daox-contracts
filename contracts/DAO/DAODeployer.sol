pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";

library DAODeployer {
    function deployCrowdsaleDAO(string _name,  string _description, address[4] modules) returns(address) {
        CrowdsaleDAO dao = new CrowdsaleDAO(_name, _description);
        dao.setStateModule(modules[0]);
        dao.setPaymentModule(modules[1]);
        dao.setVotingDecisionModule(modules[2]);
        dao.setCrowdsaleModule(modules[3]);
        dao.transferOwnership(msg.sender);

        return address(dao);
    }
}
