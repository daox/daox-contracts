pragma solidity ^0.4.11;

import "./DAO.sol";
import "./CrowdsaleDAO.sol";

contract DAOFactory {

    event DAOCreated(
        address _address,
        //string _name,
        string DAOType
    );
    mapping(address => string) DAOs;
    address public usersContract;

    function DAOFactory(address _usersContract){
        require(_usersContract != 0x0);
        usersContract = _usersContract;
    }

    function createOrdinaryDAO(string _name, string _description, uint8 _minVote, address[] _participants, address _owner) {
        address newDAO = new DAO(usersContract, _name, _description, _minVote, _participants, _owner);
        DAOs[newDAO] = _name;

        DAOCreated(newDAO, "ordinary");
    }

    function createCrowdsaleDAO(address _usersAddress, string _name, string _description, uint8 _minVote, address[] _participants, address _owner,
    uint _softCap, uint _hardCap, uint _rate, string _tokenName, string _tokenSymbol, uint _tokenDecimals, uint _startBlock, uint _endBlock) {
        address newDAO = new CrowdsaleDAO(_usersAddress, _name, _description, _minVote, _participants, _owner);
        CrowdsaleDAO dao = CrowdsaleDAO(newDAO);
        dao.initTokenParameters(_tokenName, _tokenSymbol, _tokenDecimals);
        dao.initCrowdsaleParameters(_softCap, _hardCap, _rate, _startBlock, _endBlock);

        DAOs[newDAO] = _name;

        DAOCreated(newDAO, "crowdsale");
    }
}