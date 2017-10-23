pragma solidity ^0.4.11;

import "./DAO.sol";

contract DAOFactory {
    event DAOCreated(
        address _adress,
        string _name,
        string _description,
        uint8 _minVote,
        address[] _participants
    );
    mapping(address => string) DAOs;

    function DAOFactory(){}

    function create(address _address, string _name, string _description, uint8 _minVote, address[] _participants) {
        address newDAO = new DAO(_address, _name, _description, _minVote, _participants);
        DAOs[newDAO] = _name;

        DAOCreated(_address, _name, _description, _minVote, _participants);
    }
}
