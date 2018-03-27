pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Module is VotingFields {
    enum Modules{State, Payment, VotingDecisions, Crowdsale}
    Modules public module;
    address public newModuleAddress;
    address baseVoting;

    function Module(address _baseVoting, address _dao, string _name, string _description, uint _duration, uint _module, address _newAddress) {
        require(_module >= 0 && _module <= 3);
        baseVoting = _baseVoting;
        votingType = "Module";
        module = Modules(_module);
        newModuleAddress = _newAddress;
        VotingLib.delegatecallCreate(baseVoting, _dao, _name, _description, _duration, 80);
        createOptions();
    }

    function getOptions() public constant returns(uint[2]) {
        return [options[1].votes, options[2].votes];
    }

    function addVote(uint optionID) public {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() public {
        VotingLib.delegatecallFinish(baseVoting);
        if(result.description == "no") return;

        //Sorry but solidity doesn't support `switch` keyword
        if (uint(module) == uint(Modules.State)) dao.setStateModule(newModuleAddress);
        if (uint(module) == uint(Modules.Payment)) dao.setPaymentModule(newModuleAddress);
        if (uint(module) == uint(Modules.VotingDecisions)) dao.setVotingDecisionModule(newModuleAddress);
        if (uint(module) == uint(Modules.Crowdsale)) dao.setCrowdsaleModule(newModuleAddress);
    }

    function createOptions() private {
        options[1] = VotingLib.Option(0, "yes");
        options[2] = VotingLib.Option(0, "no");
    }
}