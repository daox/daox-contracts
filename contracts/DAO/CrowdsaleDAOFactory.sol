pragma solidity ^0.4.0;

import "./DAOFactoryInterface.sol";
import "./DAODeployer.sol";

contract CrowdsaleDAOFactory is DAOFactoryInterface {
    event CrowdsaleDAOCreated(
        address _address,
        string _name
    );

    mapping(address => string) DAOs;
    address public serviceContractAddress;
    address public votingFactoryContractAddress;
    address[4] modules;

    function CrowdsaleDAOFactory(address _serviceContractAddress, address _votingFactoryAddress, address[4] _modules) {
        require(_serviceContractAddress != 0x0 && _votingFactoryAddress != 0x0);
        serviceContractAddress = _serviceContractAddress;
        votingFactoryContractAddress = _votingFactoryAddress;
        modules = _modules;

        require(votingFactoryContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
        require(serviceContractAddress.call(bytes4(keccak256("setDaoFactory(address,address)")), this, msg.sender));
    }

    function createCrowdsaleDAO(string _name, string _description) {
        address dao = DAODeployer.deployCrowdsaleDAO(_name, _description);

        dao.call(bytes4(keccak256("setStateModule(address)")), modules[0]);
        dao.call(bytes4(keccak256("setPaymentModule(address)")), modules[1]);
        dao.call(bytes4(keccak256("setVotingDecisionModule(address)")), modules[2]);
        dao.call(bytes4(keccak256("setCrowdsaleModule(address)")), modules[3]);
        DAODeployer.transferOwnership(dao, msg.sender);

        DAOs[dao] = _name;
        CrowdsaleDAOCreated(dao, _name);
    }

    function exists(address _address) constant returns (bool) {
        return keccak256(DAOs[_address]) != keccak256("");
    }
}