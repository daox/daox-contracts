pragma solidity ^0.4.0;

interface IDAO {
    function isParticipant(address _participantAddress) external constant returns (bool);

    function addParticipant(address _participantAddress) external returns (bool);

    function remove(address _participantAddress) external;

    function leave() external;

    function getParticipantsCount() public constant returns(uint);
}
