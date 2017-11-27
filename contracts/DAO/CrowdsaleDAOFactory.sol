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
        require(_usersContract != 0x0);
        usersContractAddress = _usersContractAddress;
        serviceContractAddress = _serviceContractAddress;
        votingFactoryContractAddress = _votingFactoryAddress;
        parentDAOAddress = _parentDAOAddress;
    }

    function createCrowdsaleDAO(string _name, string _description, uint8 _minVote, address _ownerAddress, address _tokenAddress,
    uint _softCap,uint _hardCap, uint _rate,uint _startBlock, uint _endBlock) {
        address newDAO = new CrowdsaleDAO(usersContractAddress, _name, _description, _minVote, _tokenAddress,
        votingFactoryContractAddress, serviceContractAddress, _ownerAddress, parentDAOAddress);
        CrowdsaleDAO dao = CrowdsaleDAO(newDAO);

        dao.initCrowdsaleParameters(_softCap, _hardCap, _rate, _startBlock, _endBlock);
        //dao.initBonuses(_team, tokenPercents, _bonusPeriods, _bonusRates);
        //dao.initHold(unholdTime);

        DAOs[newDAO] = _name;

        CrowdsaleDAOCreated(newDAO, _name);
    }

    function exists(address _address) public constant returns (bool) {
        return bytes(DAOs[_address]).length != 0;
    }
}
