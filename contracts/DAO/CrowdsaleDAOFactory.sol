pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";
import "./DAOFactoryInterface.sol";

contract CrowdsaleDAOFactory is DAOFactoryInterface {
    event DAOCreated(
        address _address,
        string _name
    );
    mapping(address => string) DAOs;
    address public usersContract;
    address public serviceContract;

    function CrowdsaleDAOFactory(address _usersContract, address _serviceContract){
        require(_usersContract != 0x0);
        usersContract = _usersContract;
        serviceContract = _serviceContract;
    }

    function createCrowdsaleDAO(string _name, string _description, uint unholdTime, uint8 _minVote, address _ownerAddress, address _tokenAddress,
    uint _softCap,uint _hardCap,uint _rate,uint _startBlock, uint _endBlock, address[] _team, uint[] tokenPercents, uint[] _bonusPeriods, uint[] _bonusRates) {
        address newDAO = new CrowdsaleDAO(usersContract, _name, _description, _minVote, _ownerAddress, _tokenAddress, serviceContract);
        CrowdsaleDAO dao = CrowdsaleDAO(newDAO);

        dao.initCrowdsaleParameters(_softCap, _hardCap, _rate, _startBlock, _endBlock);
        dao.initBonuses(_team, tokenPercents, _bonusPeriods, _bonusRates);
        dao.initHold(unholdTime);

        DAOs[newDAO] = _name;

        DAOCreated(newDAO, _name);
    }

    function exists(address _address) public constant returns (bool) {
        return bytes(DAOs[_address]).length != 0;
    }
}
