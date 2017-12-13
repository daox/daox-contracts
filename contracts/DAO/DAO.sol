pragma solidity ^0.4.0;

import "./IDAO.sol";
import "../Votings/VotingFactoryInterface.sol";

contract DAO is IDAO {
    mapping (address => bool) public participants;
    uint public participantsCount;
    address public owner;
    VotingFactoryInterface public votingFactory;
    uint public minVote;

    function isParticipant(address _participantAddress) external constant returns (bool) {
        return participants[_participantAddress];
    }

    function addParticipant(address _participantAddress) external returns (bool) {
        require(msg.sender == owner || msg.sender == _participantAddress);
        participants[_participantAddress] = true;
        participantsCount++;

        return participants[_participantAddress];
    }

    function remove(address _participantAddress) external {
        removeParticipant(_participantAddress);
    }

    function leave() external {
        removeParticipant(msg.sender);
    }

    function removeParticipant(address _address) private {
        require(participants[_address]);
        participants[_address] = false;
        participantsCount--;
    }

    function addProposal(bytes32 _description, uint _duration, bytes32[] _options) external {
        votingFactory.createProposal(msg.sender, _description, _duration, _options);
    }

    function addWithdrawal(bytes32 _description, uint _duration, uint _sum) external {
        votingFactory.createWithdrawal(msg.sender, _description, _duration, _sum, minVote);
    }

    function addRefund(bytes32 _description, uint _duration) external {
        votingFactory.createRefund(msg.sender, _description, _duration, minVote);
    }
}
