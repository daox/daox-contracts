pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract WhiteList is VotingFields {
    enum Action {Add, Remove, Flush}

    address baseVoting;
    Action public action;
    address addr = 0x0;

    function WhiteList(address _baseVoting, address _dao, bytes32 _description, uint _duration, uint _quorum, address _addr, uint _action){
        require(_addr != 0x0 || Action(_action) == Action.Flush);
        baseVoting = _baseVoting;
        votingType = "WhiteList";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, _quorum);
        addr = _addr;
        action = Action(_action);
        createOptions();
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
        bool res = (result.description == "yes");
        if(!res) return;
        if(action == Action.Flush) {
            dao.flushWhiteList();
            return;
        }
        if(action == Action.Remove) res = !res;
        dao.changeWhiteList(addr, res);
    }

    function createOptions() private {
        options[1] = VotingLib.Option(0, "yes");
        options[2] = VotingLib.Option(0, "no");
    }

    function getOptions() external constant returns(uint[2] result) {
        for (uint i = 1; i < 3; i++) {
            result[i] = options[i].votes;
        }
    }
}
