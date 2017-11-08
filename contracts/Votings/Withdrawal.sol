pragma solidity ^0.4.11;

import "./Voting.sol";

contract Withdrawal is Voting {
    uint withdrawalSum;

    function Withdrawal(address _creator, string _description, uint _duration, uint sum)
    Voting(_creator,_description, _duration)
    {
        withdrawalSum = sum;
        bytes32[] memory _options = new bytes32[](2);
        _options[0] = "yes";
        _options[1] = "no";
        createOptions(_options);
    }
}
