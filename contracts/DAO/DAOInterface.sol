pragma solidity ^0.4.11;


interface DAOInterface {
    function isParticipant(address participantAddress) constant returns (bool);

    function getMinVotes() public constant returns(uint);

    function getParticipantsCount() public constant returns(uint);

    function withdrawal(address _address, uint withdrawalSum);

    function makeRefundable();
}
