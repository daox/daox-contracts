pragma solidity ^0.4.11;

import "./DAO.sol";

contract DAOFactory {
    event DAOCreated(
        address _address,
        string _name,
        string _description,
        uint8 _minVote,
        address[] _participants
    );
    mapping(address => string) DAOs;
    address public usersContract;

    function DAOFactory(address _usersContract){
        require(_usersContract != 0x0);
        usersContract = _usersContract;
    }

    function create(string _name, string _description, uint8 _minVote, address[] _participants) {
        address newDAO = new DAO(usersContract, _name, _description, _minVote, _participants);
        DAOs[newDAO] = _name;

        DAOCreated(newDAO, _name, _description, _minVote, _participants);
    }
}


0x9BDBc894e62E00a64Afe0C674E248f6AD4AAEbCd