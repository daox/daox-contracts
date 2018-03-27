pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";

library DAODeployer {
    function deployCrowdsaleDAO(string _name,  string _description) returns(CrowdsaleDAO dao) {
        dao = new CrowdsaleDAO(_name, _description);
    }

    function transferOwnership(address _dao, address _newOwner) {
        CrowdsaleDAO(_dao).transferOwnership(_newOwner);
    }
}
