pragma solidity ^0.4.0;

interface VotingInterface {
    function voted(address _address) constant returns (uint);

    function getOptions() external constant returns(uint[] result);
}
