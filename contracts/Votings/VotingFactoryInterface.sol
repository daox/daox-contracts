pragma solidity ^0.4.11;


interface VotingFactoryInterface {
    function createProposal(address _creator, string _description, uint _duration, bytes32[] _options) constant returns (address);

    function createWithdrawal(address _creator, string _description, uint _duration, uint _sum) constant returns (address);

    function createRefund(address _creator, string _description, uint _duration) constant returns (address);
}
