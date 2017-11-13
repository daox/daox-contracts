pragma solidity ^0.4.0;

import "./CrowdsaleDAO.sol";

contract CrowdsaleDAOFactory {
    event DAOCreated(
        address _address,
        string _name
    );
    mapping(address => string) DAOs;
    address public usersContract;

    function CrowdsaleDAOFactory(address _usersContract){
        require(_usersContract != 0x0);
        usersContract = _usersContract;
    }

    function createCrowdsaleDAO(string _name, string _description, uint8 _minVote, address _ownerAddress, address _tokenAddress,
    uint _softCap,uint _hardCap,uint _rate,uint _startBlock,uint _endBlock) {
        address newDAO = new CrowdsaleDAO(usersContract, _name, _description, _minVote, _ownerAddress, _tokenAddress);
        CrowdsaleDAO dao = CrowdsaleDAO(newDAO);
        dao.initCrowdsaleParameters(_softCap, _hardCap, _rate, _startBlock, _endBlock);

        DAOs[newDAO] = _name;

        DAOCreated(newDAO, _name);
    }
}
