pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Proposal is VotingFields {
    address baseVoting;
    VotingLib.VotingType constant votingType = VotingLib.VotingType.Proposal;

    function Proposal(address _baseVoting, address _dao, address _creator, string _description, uint _duration, bytes32[10] _options){
        baseVoting = _baseVoting;
        VotingLib.delegatecallCreate(baseVoting, _dao, _creator, Common.stringToBytes32(_description), _duration, 50); //ToDo: Common.stringToBytes32 doesn't work
        createOptions(_options);
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
    }

    function createOptions(bytes32[10] _options) private {
        for (uint i = 0; i < 10; i++) {
            options[i] = VotingLib.Option(0, _options[i]);
        }
    }

    function getOptions() constant returns(uint[10] result) {
        for (uint i = 0; i < 10; i++) {
            result[i] = options[i].votes;
        }
    }
}
