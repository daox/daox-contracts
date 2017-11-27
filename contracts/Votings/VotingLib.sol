pragma solidity ^0.4.11;


library VotingLib {
    enum VotingType {Proposal, Withdrawal, Refund}

    struct Option {
        uint votes;
        bytes32 description;
    }

    function delegatecallCreate(address _v, address dao, address _creator, bytes32 _description, uint _duration, uint quorum) {
        _v.delegatecall(bytes4(keccak256("create(address,address,bytes32,uint256,uint256)")), dao, _creator, _description, _duration, quorum);
    }

    function delegatecallAddVote(address _v, uint optionID) {
        _v.delegatecall(bytes4(keccak256("addVote(uint256)")), optionID);
    }

    function delegatecallFinish(address _v) {
        _v.delegatecall(bytes4(keccak256("finish()")));
    }
}