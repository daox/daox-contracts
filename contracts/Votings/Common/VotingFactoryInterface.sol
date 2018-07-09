pragma solidity ^0.4.11;


interface VotingFactoryInterface {
    function createRegular(address _creator, string _name, string _description, uint _duration, bytes32[] _options) external returns (address);

    function createWithdrawal(address _creator, string _name, string _description, uint _duration, uint _sum, address withdrawalWallet, bool _dxc) external returns (address);

    function createRefund(address _creator, string _name, string _description, uint _duration) external returns (address);

    function createModule(address _creator, string _name, string _description, uint _duration, uint _module, address _newAddress) external returns (address);

    function createNewService(address _creator, string _name, string _description, uint _duration, address _service) external returns (address);

    function setDaoFactory(address _dao) external;
}
