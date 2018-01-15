pragma solidity ^0.4.0;

import "./VotingFactoryInterface.sol";
import "./Proposal.sol";
import "./Withdrawal.sol";
import "./Refund.sol";
import "./WhiteList.sol";
import "../DAO/DAOFactoryInterface.sol";
import "../DAO/IDAO.sol";

contract VotingFactory is VotingFactoryInterface {
    address baseVoting;
    DAOFactoryInterface daoFactory;

    function VotingFactory(address _baseVoting){
        baseVoting = _baseVoting;
    }

    function createProposal(address _creator, bytes32 _description, uint _duration, bytes32[] _options) onlyDAO onlyParticipant(_creator) external returns (address) {
        return new Proposal(baseVoting, msg.sender, _description, _duration, _options);
    }

    function createWithdrawal(address _creator, bytes32 _description, uint _duration, uint _sum, uint quorum, address withdrawalWallet) onlyDAO onlyWhiteList(withdrawalWallet) external returns (address) {
        return new Withdrawal(baseVoting, msg.sender, _description, _duration, _sum, quorum, withdrawalWallet);
    }

    function createRefund(address _creator, bytes32 _description, uint _duration, uint quorum) onlyDAO onlyParticipant(_creator) external returns (address) {
        return new Refund(baseVoting, msg.sender, _description, _duration, quorum);
    }

    function createWhiteList(address _creator, bytes32 _description, uint _duration, uint quorum, address _addr, uint action) onlyDAO onlyParticipant(_creator) external returns (address) {
        return new WhiteList(baseVoting, msg.sender, _description, _duration, quorum, _addr, action);
    }

    function setDaoFactory(address _dao) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }

    modifier onlyParticipant(address creator) {
        require(IDAO(msg.sender).isParticipant(creator));
        _;
    }

    modifier onlyWhiteList(address creator) {
        require(IDAO(msg.sender).whiteList(creator));
        _;
    }

    modifier succeededCrowdsale() {
        require(block.timestamp >= IDAO(msg.sender).endTime() && IDAO(msg.sender).weiRaised() >= IDAO(msg.sender).softCap());
        _;
    }
}
