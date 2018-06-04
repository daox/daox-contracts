pragma solidity ^0.4.0;

library DAOProxy {
    function delegatedInitState(address stateModule, address _tokenAddress, address _DXC) {
        require(stateModule.delegatecall(bytes4(keccak256("initState(address,address)")), _tokenAddress, _DXC));
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

    function delegatedWithdrawal(address votingDecisionModule, address _address, uint withdrawalSum, bool dxc) {
        require(votingDecisionModule.delegatecall(bytes4(keccak256("withdrawal(address,uint256,bool)")), _address, withdrawalSum, dxc));
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

    function delegatedInitCrowdsaleParameters(
        address crowdsaleModule,
        uint _softCap,
        uint _hardCap,
        uint _etherRate,
        uint _DXCRate,
        uint _startTime,
        uint _endTime,
        bool _dxcPayments,
        uint _lockup
    ) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("initCrowdsaleParameters(uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256)"))
        , _softCap, _hardCap, _etherRate, _DXCRate, _startTime, _endTime, _dxcPayments, _lockup));
    }

    function delegatedFinish(address crowdsaleModule) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("finish()"))));
    }

    function delegatedHandlePayment(address crowdsaleModule, address _sender, bool _commission) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("handlePayment(address,bool)")), _sender, _commission));
    }

    function delegatedHandleDXCPayment(address crowdsaleModule, address _from, uint _amount) {
        require(crowdsaleModule.delegatecall(bytes4(keccak256("handleDXCPayment(address,uint256)")), _from, _amount));
    }
}
