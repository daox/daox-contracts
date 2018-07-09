pragma solidity ^0.4.0;

import "../DAO/DAOFactoryInterface.sol";
import "../DAO/IDAO.sol";

contract BaseVotingFactory {
    address baseVoting;
    DAOFactoryInterface public daoFactory;

    constructor(address _baseVoting) public {
        baseVoting = _baseVoting;
    }

    /*
    * @dev Set dao factory address. Calls ones from just deployed DAO
    * @param _dao Address of dao factory
    */
    function setDaoFactory(address _dao) external {
        require(address(daoFactory) == 0x0 && _dao != 0x0);
        daoFactory = DAOFactoryInterface(_dao);
    }

    /*
    * @dev Throws if caller is not correct DAO
    */
    modifier onlyDAO() {
        require(daoFactory.exists(msg.sender));
        _;
    }

    /*
    * @dev Throws if creator is not participant of passed DAO
    */
    modifier onlyParticipantWithEnoughDXC(address creator) {
        require(IDAO(msg.sender).isParticipant(creator), "You need to be a participant to call this method");
        require(IDAO(msg.sender).initialCapitalIncr(creator) >= IDAO(msg.sender).votingPrice(), "You don't have enough DXC to call this method.");
        _;
    }
}
