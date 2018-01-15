pragma solidity ^0.4.0;

import "./IDAO.sol";
import "../Token/TokenInterface.sol";

contract ICrowdsaleDAO is IDAO {
    function addProposal(string _description, uint _duration, bytes32[] _options) external;

    function addWithdrawal(string _description, uint _duration, uint _sum) external;

    function addRefund(string _description, uint _duration) external;

    function makeRefundableByVotingDecision();

    function flushWhiteList() external;

    function changeWhiteList(address _addr, bool res) external;

    function holdTokens(address _address, uint duration) external;

    function withdrawal(address _address, uint withdrawalSum);

    function teamBonuses(address _address) returns (uint);

    function token() returns (TokenInterface);
}
