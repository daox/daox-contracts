pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";

library DAODeployer {
    function deployCrowdsaleDAO(
        string _name,
        string _description,
        address _serviceContractAddress,
        address _votingFactory,
        address _serviceVotingFactory,
        address _DXC,
        uint _initialCapital
    ) returns(CrowdsaleDAO dao) {
        dao = new CrowdsaleDAO(_name, _description, _serviceContractAddress, _votingFactory, _serviceVotingFactory, _DXC, _initialCapital);
    }

    function transferOwnership(address _dao, address _newOwner) {
        CrowdsaleDAO(_dao).transferOwnership(_newOwner);
    }
}
