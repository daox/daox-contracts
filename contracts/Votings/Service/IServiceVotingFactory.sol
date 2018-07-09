pragma solidity ^0.4.11;


interface IServiceVotingFactory {
    function createModule(address _creator, string _name, string _description, uint _duration, uint _module, address _newAddress) external returns (address);

    function createNewService(address _creator, string _name, string _description, uint _duration, address _service) external returns (address);

    function setDaoFactory(address _dao) external;
}
