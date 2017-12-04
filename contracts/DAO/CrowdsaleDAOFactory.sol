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
    address public parentDAOAddress;

    function CrowdsaleDAOFactory(address _usersContractAddress, address _serviceContractAddress, address _votingFactoryAddress, address _parentDAOAddress){
        require(_usersContractAddress != 0x0 && _serviceContractAddress != 0x0 && _votingFactoryAddress != 0x0 && _parentDAOAddress != 0x0);
        usersContractAddress = _usersContractAddress;
        serviceContractAddress = _serviceContractAddress;
        votingFactoryContractAddress = _votingFactoryAddress;
        parentDAOAddress = _parentDAOAddress;

        require(votingFactoryContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
        require(serviceContractAddress.call(bytes4(keccak256("setDaoFactory(address,address)")), this, msg.sender));
    }

    function createCrowdsaleDAO(string _name, string _description, uint8 _minVote, address _ownerAddress, address _tokenAddress,
    uint _softCap,uint _hardCap, uint _rate,uint _startBlock, uint _endBlock) returns(address) {
        address dao = new CrowdsaleDAO(usersContractAddress, _name, _description, _minVote, _tokenAddress,
        votingFactoryContractAddress, serviceContractAddress, _ownerAddress, parentDAOAddress);

        DAOs[dao] = _name;

        CrowdsaleDAOCreated(dao, _name);

        return dao;
    }

    function exists(address _address) public constant returns (bool) {
        return keccak256(DAOs[_address]) != keccak256("");
    }
}
