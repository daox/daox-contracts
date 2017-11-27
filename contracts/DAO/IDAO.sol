pragma solidity ^0.4.0;

interface IDAO {
    function isParticipant(address _participantAddress) external constant returns (bool);

    function addParticipant(address _participantAddress) external returns (bool);

    function remove(address _participantAddress) external;

    function leave() external;

    function removeParticipant(address _address) private;

    function addProposal(string _description, uint _duration, bytes32[] _options) external;

    function addWithdrawal(string _description, uint _duration, uint _sum) external;

    function addRefund(string _description, uint _duration) external;
}
