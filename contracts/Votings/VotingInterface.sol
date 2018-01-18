pragma solidity ^0.4.0;

interface VotingInterface {
    mapping (address => uint) public voted;

    function getOptions() external constant returns(uint[] result);
}
