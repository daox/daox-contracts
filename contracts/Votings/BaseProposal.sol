pragma solidity ^0.4.0;

import "./VotingLib.sol";
import "./VotingFields.sol";

contract BaseProposal is VotingFields {
    address baseVoting;

    /*
    * @dev Returns amount of votes for `yes` and `no` options
    */
    function getOptions() public constant returns(uint[2]) {
        return [options[1].votes, options[2].votes];
    }

    /*
    * @dev Delegates request of adding vote to the Voting base contract
    * @param _optionID ID of option which will be added as vote
    */
    function addVote(uint _optionID) public {
        VotingLib.delegatecallAddVote(baseVoting, _optionID);
    }

    /*
    * @dev Initiates options `yes` and `no`
    */
    function createOptions() internal {
        options[1] = VotingLib.Option(0, "yes");
        options[2] = VotingLib.Option(0, "no");
    }
}
