pragma solidity 0.4.24;

import "./VotingFactoryInterface.sol";
import "./Regular.sol";
import "./Withdrawal.sol";
import "./Refund.sol";
import "./Module.sol";
import "../DAO/DAOFactoryInterface.sol";
import "../DAO/IDAO.sol";

contract VotingFactory is VotingFactoryInterface {
    address baseVoting;
    DAOFactoryInterface public daoFactory;

    function VotingFactory(address _baseVoting) {
        baseVoting = _baseVoting;
    }

    /*
    * @dev Create regular proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _options Voting's options
    */
    function createRegular(address _creator, string _name, string _description, uint _duration, bytes32[] _options)
        external
        onlyDAO
        onlyParticipantWithEnoughDXC(_creator)
        returns (address)
    {
        return new Regular(baseVoting, msg.sender, _name, _description, _duration, _options);
    }

    /*
    * @dev Create withdrawal proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _sum Sum to withdraw from DAO
    * @param _withdrawalWallet Address to send withdrawal sum
    * @param _dxc Should withdrawal sum be interpret as amount of DXC tokens
    */
    function createWithdrawal(address _creator, string _name, string _description, uint _duration, uint _sum, address _withdrawalWallet, bool _dxc)
        external
        onlyTeamMember(_creator)
        onlyDAO
        onlyWhiteList(_withdrawalWallet)
        returns (address)
    {
        return new Withdrawal(baseVoting, msg.sender, _name, _description, _duration, _sum, _withdrawalWallet, _dxc);
    }

    /*
    * @dev Create refund proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    */
    function createRefund(address _creator, string _name, string _description, uint _duration) external onlyDAO onlyParticipantWithEnoughDXC(_creator) returns (address) {
        return new Refund(baseVoting, msg.sender, _name, _description, _duration);
    }

    /*
    * @dev Create module proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _module Which module should be changed
    * @param _newAddress Address of new module
    */
    function createModule(address _creator, string _name, string _description, uint _duration, uint _module, address _newAddress)
        external
        onlyDAO
        onlyParticipantWithEnoughDXC(_creator)
        returns (address)
    {
        return new Module(baseVoting, msg.sender, _name, _description, _duration, _module, _newAddress);
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

    /*
    * @dev Throws if creator is not team member of passed DAO
    */
    modifier onlyTeamMember(address creator) {
        require(IDAO(msg.sender).teamMap(creator));
        _;
    }

    /*
    * @dev Throws if creator is not member of white list in specified DAO
    */
    modifier onlyWhiteList(address creator) {
        require(IDAO(msg.sender).whiteList(creator));
        _;
    }
}
