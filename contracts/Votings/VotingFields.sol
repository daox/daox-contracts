pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "../DAO/ICrowdsaleDAO.sol";

contract VotingFields {
    ICrowdsaleDAO dao;
    address public creator;
    bytes32 public description;
    VotingLib.Option[10] options;
    mapping (address => bool) public voted;
    VotingLib.Option result;
    uint public votesCount;
    uint public duration; // UNIX
    uint public created_at; // UNIX
    bool public finished = false;
    uint public quorum;
}
