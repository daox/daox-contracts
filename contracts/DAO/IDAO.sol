pragma solidity ^0.4.0;

contract IDAO {
    uint public endTime;
    uint public weiRaised;
    uint public softCap;

    function isParticipant(address _participantAddress) external constant returns (bool);

    function whiteList(address _address) constant returns (bool);
}
