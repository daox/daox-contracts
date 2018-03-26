pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "../DAO/ICrowdsaleDAO.sol";

contract VotingFields {
    ICrowdsaleDAO dao;
    string public name;
    string public description;
    VotingLib.Option[11] public options;
    mapping (address => uint) public voted;
    VotingLib.Option public result;
    uint public votesCount;
    uint public duration; // UNIX
    uint public created_at = now;
    bool public finished = false;
    uint public quorum;
    string public votingType;
    uint public minimalDuration = 60 * 60 * 24 * 7; // 7 days
}
