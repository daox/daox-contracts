pragma solidity ^0.4.11;


interface DAOInterface {
    function isParticipant(address participantAddress) constant returns (bool);

    function getMinVotes() public constant returns(uint8);

    function getParticipantsCount() public constant returns(uint);
}
