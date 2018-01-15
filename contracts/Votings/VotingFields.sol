pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "../DAO/ICrowdsaleDAO.sol";

contract VotingFields {
    ICrowdsaleDAO dao;
    bytes32 public description;
    VotingLib.Option[10] public options;
    mapping (address => bool) public voted;
    VotingLib.Option public result;
    uint public votesCount;
    uint public duration; // UNIX
    uint public created_at = now;
    bool public finished = false;
    uint public quorum;
    bytes32 public votingType;
}
