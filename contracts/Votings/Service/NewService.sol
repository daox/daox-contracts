pragma solidity ^0.4.0;

import "../VotingLib.sol";
import "../../Common.sol";
import "../BaseProposal.sol";

contract NewService is BaseProposal {
    address public service;

    function NewService(address _baseVoting, address _dao, string _name, string _description, uint _duration, address _service) {
        VotingLib.isValidService(_dao, _service);
        baseVoting = _baseVoting;
        service = _service;
        VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 80);
        createOptions();
    }

    /*
    * @dev Delegates request of finishing to the Voting base contract
    */
    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "yes") dao.connectService(service);
    }
}