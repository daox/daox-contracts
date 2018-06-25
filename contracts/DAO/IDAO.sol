pragma solidity ^0.4.0;

contract IDAO {
    function isParticipant(address _participantAddress) external constant returns (bool);

    function teamMap(address _address) external constant returns (bool);

    function whiteList(address _address) constant returns (bool);

    function votingDXCDeposit(address _address) constant returns (uint);

    function votingPrice() constant returns (uint);
}
