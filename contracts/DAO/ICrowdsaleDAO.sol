pragma solidity ^0.4.0;

import "./IDAO.sol";
import "../Token/TokenInterface.sol";

contract ICrowdsaleDAO is IDAO {
    function addProposal(string _description, uint _duration, bytes32[] _options) external;

    function addWithdrawal(string _description, uint _duration, uint _sum) external;

    function addRefund(string _description, uint _duration) external;

    function addModule(string _description, uint _duration, uint _module, address _newAddress) external;

    function makeRefundableByVotingDecision();

    function holdTokens(address _address, uint duration) external;

    function withdrawal(address _address, uint withdrawalSum);

    function setStateModule(address _stateModule);

    function setPaymentModule(address _paymentModule);

    function setVotingDecisionModule(address _votingDecisionModule);

    function setCrowdsaleModule(address _crowdsaleModule);

    function teamBonuses(address _address) returns (uint);

    function token() returns (TokenInterface);

    bool public crowdsaleFinished;
    uint public teamTokensAmount;
}
