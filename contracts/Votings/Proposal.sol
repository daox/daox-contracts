pragma solidity ^0.4.0;

import "./Voting.sol";

contract Proposal is Voting {
    function Proposal(address _creator, string _description, uint _duration, bytes32[] _options)
    Voting(_creator,_description, _duration)
    {
        createOptions(_options);
    }
}
