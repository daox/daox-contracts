pragma solidity ^0.4.0;

import "./VotingFactoryInterface.sol";
import "./Proposal.sol";
import "./Withdrawal.sol";
import "./Refund.sol";
import "./WhiteList.sol";
import "../DAO/DAOFactoryInterface.sol";

contract VotingFactory is VotingFactoryInterface {
    address baseVoting;
    DAOFactoryInterface daoFactory;

    function VotingFactory(address _baseVoting){
        baseVoting = _baseVoting;
    }

    function createProposal(address _creator, bytes32 _description, uint _duration, bytes32[] _options) onlyDAO external returns (address) {
        require(_options.length <= 10);

        return new Proposal(baseVoting, msg.sender, _creator, _description, _duration, _options);
    }

    function createWithdrawal(address _creator, bytes32 _description, uint _duration, uint _sum, uint quorum) onlyDAO external returns (address) {
        require(_sum > 0);

        return new Withdrawal(baseVoting, msg.sender, _creator, _description, _duration, _sum, quorum);
    }

    function createRefund(address _creator, bytes32 _description, uint _duration, uint quorum) onlyDAO external returns (address) {
        return new Refund(baseVoting, msg.sender, _creator, _description, _duration, quorum);
    }

    function createWhiteList(address _creator, bytes32 _description, uint _duration, uint quorum, address _addr, uint action) onlyDAO external returns (address) {
        return new WhiteList(baseVoting, msg.sender, _creator, _description, _duration, quorum, _addr, action);
    }

    function setDaoFactory(address _dao) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }
}
