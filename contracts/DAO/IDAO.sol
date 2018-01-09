pragma solidity ^0.4.0;

interface IDAO {
    function isParticipant(address _participantAddress) external constant returns (bool);

    function whiteList(address _address) constant returns (bool);
}
