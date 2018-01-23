pragma solidity ^0.4.11;


interface VotingFactoryInterface {
    function createProposal(address _creator, bytes32 _description, uint _duration, bytes32[] _options) external returns (address);

    function createWithdrawal(address _creator, bytes32 _description, uint _duration, uint _sum, address withdrawalWallet) external returns (address);

    function createRefund(address _creator, bytes32 _description, uint _duration) external returns (address);

    function createModule(address _creator, bytes32 _description, uint _duration, uint _module, address _newAddress) external returns (address);

    function setDaoFactory(address _dao) external;
}
