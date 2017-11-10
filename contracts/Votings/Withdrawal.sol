pragma solidity ^0.4.11;

import "./Voting.sol";

contract Withdrawal is Voting {
    uint public withdrawalSum;
    bool public votingPassed;

    function Withdrawal(address _creator, string _description, uint _duration, uint sum)
    Voting(_creator,_description, _duration)
    {
        withdrawalSum = sum;
        bytes32[] memory _options = new bytes32[](2);
        _options[0] = "yes";
        _options[1] = "no";
        createOptions(_options);
    }

    function finish() constant returns (bool) {
        bool finishResult = Voting.finish();
        assert(finishResult);
        if(withdrawalSum > 0 && result.description == "yes") {
            votingPassed = true;
            assert(!creator.call.value(withdrawalSum*1 ether)());
        }

        return true;
    }
}
