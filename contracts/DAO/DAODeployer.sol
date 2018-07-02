pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";

library DAODeployer {
    function deployCrowdsaleDAO(
        string _name,
        string _description,
        address _serviceContractAddress,
        address _votingFactoryContractAddress,
        address _DXC,
        uint _initialCapital
    ) returns(CrowdsaleDAO dao) {
        dao = new CrowdsaleDAO(_name, _description, _serviceContractAddress, _votingFactoryContractAddress, _DXC, _initialCapital);
    }

    function transferOwnership(address _dao, address _newOwner) {
        CrowdsaleDAO(_dao).transferOwnership(_newOwner);
    }
}
