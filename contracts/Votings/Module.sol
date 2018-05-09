pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "../Common.sol";
import "./BaseProposal.sol";

contract Module is BaseProposal {
    enum Modules{State, Payment, VotingDecisions, Crowdsale, VotingFactory}
    Modules public module;
    address public newModuleAddress;

    function Module(address _baseVoting, address _dao, string _name, string _description, uint _duration, uint _module, address _newAddress) {
        require(_module >= 0 && _module <= 4);
        baseVoting = _baseVoting;
        votingType = "Module";
        module = Modules(_module);
        newModuleAddress = _newAddress;
        VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 80);
        createOptions();
    }

    /*
    * @dev Delegates request of finishing to the Voting base contract
    */
    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "no") return;

        //Sorry but solidity doesn't support `switch` keyword
        if (uint(module) == uint(Modules.State)) dao.setStateModule(newModuleAddress);
        if (uint(module) == uint(Modules.Payment)) dao.setPaymentModule(newModuleAddress);
        if (uint(module) == uint(Modules.VotingDecisions)) dao.setVotingDecisionModule(newModuleAddress);
        if (uint(module) == uint(Modules.Crowdsale)) dao.setCrowdsaleModule(newModuleAddress);
        if (uint(module) == uint(Modules.VotingFactory)) dao.setVotingFactoryAddress(newModuleAddress);
    }
}