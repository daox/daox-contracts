pragma solidity ^0.4.0;

import "./DAO/CrowdsaleDAO.sol";

library DAODeployer {
    function deployCrowdsaleDAO(string _name,  string _description, address _ownerAddress) returns(address) {
        CrowdsaleDAO dao = new CrowdsaleDAO(_name, _description, _ownerAddress);

        return address(dao);
    }
}
