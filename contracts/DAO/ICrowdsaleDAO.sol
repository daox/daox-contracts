pragma solidity ^0.4.0;

import "./IDAO.sol";
import "../Token/TokenInterface.sol";

contract ICrowdsaleDAO is IDAO {
    bool public crowdsaleFinished;
    uint public teamTokensAmount;
    uint public endTime;
    uint public weiRaised;
    uint public softCap;
    uint public fundsRaised;

    function addRegular(string _description, uint _duration, bytes32[] _options) external;

    function addWithdrawal(string _description, uint _duration, uint _sum) external;

    function addRefund(string _description, uint _duration) external;

    function addModule(string _description, uint _duration, uint _module, address _newAddress) external;

    function holdTokens(address _address, uint duration) external;

    function makeRefundableByVotingDecision();

    function withdrawal(address _address, uint withdrawalSum, bool dxc);

    function setStateModule(address _stateModule);

    function setPaymentModule(address _paymentModule);

    function setVotingDecisionModule(address _votingDecisionModule);

    function setCrowdsaleModule(address _crowdsaleModule);

    function setVotingFactoryAddress(address _votingFactory);

    function teamBonuses(address _address) constant returns (uint);

    function votings(address _address) constant returns (address);

    function token() constant returns (TokenInterface);

    function DXC() constant returns(TokenInterface);
}
