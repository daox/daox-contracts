pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";
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

    function createCrowdsaleDAO(string _name, string _description) returns(address) {
        address dao = DAODeployer.deployCrowdsaleDAO(_name, _description, modules);
        DAOs[dao] = _name;
        CrowdsaleDAOCreated(dao, _name);

        return dao;
    }

    function exists(address _address) public constant returns (bool) {
        return keccak256(DAOs[_address]) != keccak256("");
    }
}