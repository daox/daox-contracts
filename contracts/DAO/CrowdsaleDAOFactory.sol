pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";
import "./DAOFactoryInterface.sol";

contract CrowdsaleDAOFactory is DAOFactoryInterface {
    event CrowdsaleDAOCreated(
        address _address,
        string _name
    );

    mapping(address => string) DAOs;
    address public usersContractAddress;
    address public serviceContractAddress;
    address public votingFactoryContractAddress;
    address public proxyCrowdsaleDao;

    function CrowdsaleDAOFactory(address _usersContractAddress, address _serviceContractAddress, address _votingFactoryAddress) {
        require(_usersContractAddress != 0x0 && _serviceContractAddress != 0x0 && _votingFactoryAddress != 0x0);
        usersContractAddress = _usersContractAddress;
        serviceContractAddress = _serviceContractAddress;
        votingFactoryContractAddress = _votingFactoryAddress;

        require(votingFactoryContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
        require(serviceContractAddress.call(bytes4(keccak256("setDaoFactory(address,address)")), this, msg.sender));
    }

    function createCrowdsaleDAO(string _name, string _description, uint8 _minVote, address _ownerAddress, address _tokenAddress) returns(address) {
        address dao = new CrowdsaleDAO(_name, _description, _ownerAddress);

        DAOs[dao] = _name;

        CrowdsaleDAOCreated(dao, _name);

        return dao;
    }

    function exists(address _address) public constant returns (bool) {
        return keccak256(DAOs[_address]) != keccak256("");
    }
}
