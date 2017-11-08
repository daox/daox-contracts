pragma solidity ^0.4.11;

import "./DAO.sol";
import "./CrowdsaleDAO.sol";

contract DAOFactory {

    event DAOCreated(
        address _address,
        string _name,
        string _description,
        uint8 _minVote,
        address[] _participants,
        string type
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

        DAOCreated(newDAO, _name, _description, _minVote, _participants, "ordinary");
    }

    function createCrowdsaleDAO(address _usersAddress, string _name, string _description, uint8 _minVote, address[] _participants,
    uint _softCap, uint _hardCap, string _tokenName, string _tokenSymbol, uint _tokenDecimals) {
        address newDAO = new CrowdsaleDAO(_usersAddress, _name, _description, _minVote, _participants, _softCap, _hardCap, _tokenName, _tokenSymbol, _tokenDecimals);
        DAOs[newDAO] = _name;

        DAOCreated(newDAO, _name, _description, _minVote, _participants, "crowdsale");
    }
}