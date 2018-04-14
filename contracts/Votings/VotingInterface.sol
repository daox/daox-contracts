pragma solidity ^0.4.0;

interface VotingInterface {
    function addVote(uint optionID) external;

    function finish() external;

    function getOptions() external constant returns(uint[2] result);

    function finished() external constant returns(bool);

    function voted(address _address) external constant returns (uint);
}