pragma solidity ^0.4.0;

import "./DAOFactoryInterface.sol";
import "./DAODeployer.sol";
import "../Common.sol";

contract CrowdsaleDAOFactory is DAOFactoryInterface {
    event CrowdsaleDAOCreated(
        address _address,
        string _name
    );

    address public serviceContractAddress;
    address public votingFactoryContractAddress;
    mapping(address => string) DAOs;
    address[4] modules;

    function CrowdsaleDAOFactory(address _serviceContractAddress, address _votingFactoryAddress, address[4] _modules) {
        require(_serviceContractAddress != 0x0 && _votingFactoryAddress != 0x0);
        serviceContractAddress = _serviceContractAddress;
        votingFactoryContractAddress = _votingFactoryAddress;
        modules = _modules;

        require(votingFactoryContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
        require(serviceContractAddress.call(bytes4(keccak256("setDaoFactory(address,address)")), this, msg.sender));
    }

    function exists(address _address) external constant returns (bool) {
        return keccak256(DAOs[_address]) != keccak256("");
    }

    function createCrowdsaleDAO(string _name, string _description) public {
        address dao = DAODeployer.deployCrowdsaleDAO(_name, Common.stringToBytes32(_description));

        require(dao.call(bytes4(keccak256("setStateModule(address)")), modules[0]));
        require(dao.call(bytes4(keccak256("setPaymentModule(address)")), modules[1]));
        require(dao.call(bytes4(keccak256("setVotingDecisionModule(address)")), modules[2]));
        require(dao.call(bytes4(keccak256("setCrowdsaleModule(address)")), modules[3]));
        DAODeployer.transferOwnership(dao, msg.sender);

        DAOs[dao] = _name;
        CrowdsaleDAOCreated(dao, _name);
    }
}