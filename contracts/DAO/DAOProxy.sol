pragma solidity ^0.4.0;

library DAOProxy {
    function delegatedInitState(address stateModule, uint8 _minVote, address _usersAddress, address _tokenAddress, address _votingFactory, address _serviceContract) {
        require(stateModule.delegatecall(bytes4(keccak256("initState(uint8,address,address,address,address)")), _minVote, _usersAddress, _tokenAddress, _votingFactory, _serviceContract));
    }

    function delegatedHoldState(address stateModule, uint _tokenHoldTime) {
        require(stateModule.delegatecall(bytes4(keccak256("initHold(uint256)")), _tokenHoldTime));
    }

    function delegatedGetCommissionTokens(address paymentModule) {
        require(paymentModule.delegatecall(bytes4(keccak256("getCommissionTokens()"))));
    }

    function delegatedRefund(address paymentModule) {
        require(paymentModule.delegatecall(bytes4(keccak256("refund()"))));
    }

    function delegatedRefundSoftCap(address paymentModule) {
        require(paymentModule.delegatecall(bytes4(keccak256("refundSoftCap()"))));
    }

    function delegatedWithdrawal(address votingDecisionModule, address _address, uint withdrawalSum) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("withdrawal(address,uint256)")), _address, withdrawalSum));
    }

    function delegatedMakeRefundableByUser(address votingDecisionModule) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("makeRefundableByUser()"))));
    }

    function delegatedMakeRefundableByVotingDecision(address votingDecisionModule) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("makeRefundableByVotingDecision()"))));
    }

    function delegatedHoldTokens(address votingDecisionModule, address _address, uint duration) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("holdTokens(address,uint256)")), _address, duration));
    }

    function delegatedFlushWhiteList(address votingDecisionModule) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("flushWhiteList()"))));
    }

    function delegatedChangeWhiteList(address votingDecisionModule, address _addr, bool res) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("changeWhiteList(address,bool)")), _addr, res));
    }

    function delegatedInitCrowdsaleParameters(address crowdsaleModule, uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("initCrowdsaleParameters(uint256,uint256,uint256,uint256,uint256)")), _softCap, _hardCap, _rate, _startBlock, _endBlock));
    }

    function delegatedFinish(address crowdsaleModule) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("finish()"))));
    }

    function delegatedHandlePayment(address crowdsaleModule, address _sender, bool _commission) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("handlePayment(address,bool)")), _sender, _commission));
    }
}
