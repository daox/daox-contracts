pragma solidity ^0.4.0;

import "./VotingFactoryInterface.sol";
import "./Proposal.sol";
import "./Withdrawal.sol";
import "./Refund.sol";
import "./Module.sol";
import "../DAO/DAOFactoryInterface.sol";
import "../DAO/IDAO.sol";

contract VotingFactory is VotingFactoryInterface {
    address baseVoting;
    DAOFactoryInterface daoFactory;

    function VotingFactory(address _baseVoting) {
        baseVoting = _baseVoting;
    }

    function createProposal(address _creator, bytes32 _description, uint _duration, bytes32[] _options)
        external
        onlyDAO
        onlyParticipant(_creator)
        returns (address)
    {
        return new Proposal(baseVoting, msg.sender, _description, _duration, _options);
    }

    function createWithdrawal(address _creator, bytes32 _description, uint _duration, uint _sum, address withdrawalWallet, bool dxc)
        external
        onlyParticipant(_creator)
        onlyDAO
        onlyWhiteList(withdrawalWallet)
        returns (address)
    {
        return new Withdrawal(baseVoting, msg.sender, _description, _duration, _sum, withdrawalWallet, dxc);
    }

    function createRefund(address _creator, bytes32 _description, uint _duration) onlyDAO onlyParticipant(_creator) external returns (address) {
        return new Refund(baseVoting, msg.sender, _description, _duration);
    }

    function createModule(address _creator, bytes32 _description, uint _duration, uint _module, address _newAddress)
        external
        onlyDAO
        onlyParticipant(_creator)
        returns (address)
    {
        return new Module(baseVoting, msg.sender, _description, _duration, _module, _newAddress);
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
}
