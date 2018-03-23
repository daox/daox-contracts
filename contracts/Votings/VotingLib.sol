pragma solidity ^0.4.11;

import "../DAO/ICrowdsaleDAO.sol";

library VotingLib {
    struct Option {
        uint votes;
        bytes32 description;
    }

    function delegatecallCreate(address _v, address _dao, bytes32 _description, uint _duration, uint _quorum) {
        require(_v.delegatecall(bytes4(keccak256("create(address,bytes32,uint256,uint256)")), _dao, _description, _duration, _quorum));
    }

    function delegatecallAddVote(address _v, uint optionID) {
        require(_v.delegatecall(bytes4(keccak256("addVote(uint256)")), optionID));
    }

    function delegatecallFinish(address _v) {
        require(_v.delegatecall(bytes4(keccak256("finish()"))));
    }

    function isValidWithdrawal(address _dao, uint _sum, bool _dxc) constant returns(bool) {
        return !_dxc ? _dao.balance >= _sum  : ICrowdsaleDAO(_dao).DXC().balanceOf(_dao) >= _sum;
    }
}