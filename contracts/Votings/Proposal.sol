pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";
import "../Common.sol";

contract Proposal is VotingFields {
    address baseVoting;

    function Proposal(address _baseVoting, address _dao, bytes32 _description, uint _duration, bytes32[] _options) {
        require(_options.length >= 2 && _options.length <= 10);
        baseVoting = _baseVoting;
        votingType = "Proposal";
        VotingLib.delegatecallCreate(baseVoting, _dao, _description, _duration, 0);
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
            options[i + 1] = VotingLib.Option(0, _options[i]);
        }
    }

    function getOptions() external constant returns(uint[10]) {
        return [options[1].votes, options[2].votes, options[3].votes, options[4].votes, options[5].votes,
        options[6].votes, options[7].votes, options[8].votes, options[9].votes, options[10].votes];
    }
}
