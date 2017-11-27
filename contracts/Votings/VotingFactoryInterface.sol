pragma solidity ^0.4.11;


interface VotingFactoryInterface {
    function createProposal(address _creator, string _description, uint _duration, bytes32[] _options) external returns (address);

    function createWithdrawal(address _creator, string _description, uint _duration, uint _sum, uint quorum) external returns (address);

    function createRefund(address _creator, string _description, uint _duration, uint quorum) external returns (address);
}