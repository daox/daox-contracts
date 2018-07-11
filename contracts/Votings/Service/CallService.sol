pragma solidity 0.4.24;

import "../VotingLib.sol";
import "../../Common.sol";
import "../BaseProposal.sol";

contract CallService is BaseProposal {
    address public service;
    bytes32 public method;
    bytes32[10] public args;

    function CallService(address _baseVoting, address _dao, string _name, string _description, uint _duration, address _service, bytes32 _method, bytes32[10] _args) {
        require(VotingLib.serviceConnected(_dao, _service), "Service must be connected to call it");
        VotingLib.checkServicePrice("call", _dao, _service);
        baseVoting = _baseVoting;
        service = _service;
        method = _method;
        args = _args;
        VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 80);
        createOptions();
    }

    /*
    * @dev Delegates request of finishing to the Voting base contract
    */
    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.callService(service, method, args);
    }
}