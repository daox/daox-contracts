pragma solidity ^0.4.0;

import "./VotingFactoryInterface.sol";
import "./Proposal.sol";
import "./Withdrawal.sol";
import "./Refund.sol";

contract VotingFactory is VotingFactoryInterface {
    address baseVoting;

    function VotingFactory(address _baseVoting){
        baseVoting = _baseVoting;
    }

    function createProposal(address _creator, string _description, uint _duration, bytes32[] _options) constant returns (address) {
        return new Proposal(baseVoting, msg.sender, _creator, _description, _duration, _options);
    }

    function createWithdrawal(address _creator, string _description, uint _duration, uint _sum, uint quorum) constant returns (address) {
        return new Withdrawal(baseVoting, msg.sender, _creator, _description, _duration, _sum, quorum);
    }

    function createRefund(address _creator, string _description, uint _duration, uint quorum) constant returns (address) {
        return new Refund(baseVoting, msg.sender, _creator, _description, _duration, quorum);
    }
}
