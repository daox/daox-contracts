pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "../DAO/DAOInterface.sol";

contract VotingFields {
    DAOInterface dao;
    address public creator;
    bytes32 public description;
    VotingLib.Option[10] options;
    mapping (address => bool) public voted;
    VotingLib.Option result;
    uint public votesCount;
    uint public duration; // UNIX
    uint public constant created_at = block.timestamp; // UNIX
    bool public finished = false;
    uint public quorum;
}
