pragma solidity ^0.4.11;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract WhiteList is VotingFields {
    enum Action {Add, Remove, Flush}

    address baseVoting;
    Action action;
    address addr = 0x0;
    VotingLib.VotingType constant votingType = VotingLib.VotingType.WhiteList;

    function WhiteList(address _baseVoting, address _dao, address _creator, string _description, uint _duration, uint _quorum, address _addr, uint _action){
        require(_addr != 0x0 || Action(_action) == Action.Flush);
        baseVoting = _baseVoting;
        VotingLib.delegatecallCreate(baseVoting, _dao, _creator, Common.stringToBytes32(_description), _duration, _quorum);
        addr = _addr;
        action = Action(_action);
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() constant returns (bool) {
        VotingLib.delegatecallFinish(baseVoting);
        bool res = (result.description == "yes");
        if(!res) return false;
        if(action == Action.Flush) {
            dao.flushWhiteList();
            return true;
        }
        if(action == Action.Remove) res = !res;
        dao.changeWhiteList(addr, res);

        return true;
    }

    function createOptions() private {
        options[0] = VotingLib.Option(0, "yes");
        options[1] = VotingLib.Option(0, "no");
    }
}
