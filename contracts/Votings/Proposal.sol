pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Proposal is VotingFields {
    address baseVoting;
    VotingLib.VotingType constant votingType = VotingLib.VotingType.Proposal;

    function Proposal(address _baseVoting, address _dao, address _creator, bytes32 _description, uint _duration, bytes32[] _options){
        require(_options.length <= 10);
        baseVoting = _baseVoting;
        VotingLib.delegatecallCreate(baseVoting, _dao, _creator, _description, _duration, 50);
        createOptions(_options);
    }

    function addVote(uint optionID) {
        VotingLib.delegatecallAddVote(baseVoting, optionID);
    }

    function finish() {
        VotingLib.delegatecallFinish(baseVoting);
    }

    function createOptions(bytes32[] _options) private {
        for (uint i = 0; i < _options.length; i++) {
            options[i] = VotingLib.Option(0, _options[i]);
        }
    }

    function getOptions() external constant returns(uint[] result) {
        for (uint i = 0; i < 10; i++) {
            result[i] = options[i].votes;
        }
    }
}
