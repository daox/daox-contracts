pragma solidity 0.4.24;

import "./Module.sol";
import "./NewService.sol";
import "../BaseVotingFactory.sol";


contract ServiceVotingFactory is BaseVotingFactory {

    constructor(address _baseVoting) BaseVotingFactory(_baseVoting) {}

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
    * @dev Create new service proposal with passed parameters. Calls from DAO contract
    * @param _creator Address of caller of DAO's respectively function
    * @param _name Voting's name
    * @param _description Voting's description
    * @param _duration Voting's duration
    * @param _newAddress Address of new service
    */
    function createNewService(address _creator, string _name, string _description, uint _duration, address _service)
        external
        onlyDAO
        onlyParticipantWithEnoughDXC(_creator)
        returns (address)
    {
        return new NewService(baseVoting, msg.sender, _name, _description, _duration, _service);
    }
}
