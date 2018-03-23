pragma solidity ^0.4.0;

import "../Token/TokenInterface.sol";
import "../Votings/VotingFactoryInterface.sol";

library DAOLib {
    event VotingCreated(
        address voting,
        string votingType,
        address dao,
        bytes32 description,
        uint duration,
        address sender
    );

    function handleFinishedCrowdsale(TokenInterface token, uint commissionRaised, address serviceContract, uint[] teamBonuses, address[] team, uint[] teamHold) returns (uint) {
        uint commission = (commissionRaised / 100) * 4;
        serviceContract.call.gas(200000).value(commission)();
        uint totalSupply = token.totalSupply() / 100;
        uint teamTokensAmount = 0;
        for (uint i = 0; i < team.length; i++) {
            uint teamMemberTokensAmount = totalSupply * teamBonuses[i];
            teamTokensAmount += teamMemberTokensAmount;
            token.mint(team[i], teamMemberTokensAmount);
            token.hold(team[i], teamHold[i]);
        }

        return teamTokensAmount;
    }

    function delegateRemove(address _parentAddress, address _participantAddress) {
        require(_parentAddress.delegatecall(bytes4(keccak256("remove(address)")), _participantAddress));
    }

    function delegatedCreateProposal(VotingFactoryInterface _votingFactory, bytes32 _description, uint _duration, bytes32[] _options, address _dao) returns (address) {
        address _votingAddress = _votingFactory.createProposal(msg.sender, _description, _duration, _options);
        VotingCreated(_votingAddress, "Proposal", _dao, _description, _duration, msg.sender);

        return _votingAddress;
    }

    function delegatedCreateWithdrawal(VotingFactoryInterface _votingFactory, bytes32 _description, uint _duration, uint _sum, address withdrawalWallet, bool dxc, address _dao)
        returns (address)
    {
        address _votingAddress = _votingFactory.createWithdrawal(msg.sender, _description, _duration, _sum, withdrawalWallet, dxc);
        VotingCreated(_votingAddress, "Withdrawal", _dao, _description, _duration, msg.sender);

        return _votingAddress;
    }

    function delegatedCreateRefund(VotingFactoryInterface _votingFactory, bytes32 _description, uint _duration, address _dao) returns (address) {
        address _votingAddress = _votingFactory.createRefund(msg.sender, _description, _duration);
        VotingCreated(_votingAddress, "Refund", _dao, _description, _duration, msg.sender);

        return _votingAddress;
    }

    function delegatedCreateModule(VotingFactoryInterface _votingFactory, bytes32 _description, uint _duration, uint _module, address _newAddress, address _dao) returns (address) {
        address _votingAddress = _votingFactory.createModule(msg.sender, _description, _duration, _module, _newAddress);
        VotingCreated(_votingAddress, "Module", _dao, _description, _duration, msg.sender);

        return _votingAddress;
    }

    function delegatedInitCrowdsaleParameters(address _p, uint softCap, uint hardCap, uint etherRate, uint startTime, uint endTime) {
        require(_p.delegatecall(bytes4(keccak256("initCrowdsaleParameters(uint256,uint256,uint256,uint256,uint256)")), softCap, hardCap, etherRate, startTime, endTime));
    }

    function delegatedCreate(address _p, address _usersAddress, uint8 _minVote, address _tokenAddress,
        address _votingFactory, address _serviceContract, address _parentAddress) {
        require(_p.delegatecall(bytes4(keccak256("create(address,uint8,address,address,address,address)")),
            _usersAddress, _minVote, _tokenAddress, _votingFactory, _serviceContract, _parentAddress));
    }

    function delegatedHandlePayment(address _p, address sender, bool commission) {
        require(_p.delegatecall(bytes4(keccak256("handlePayment(address,bool)")), sender, commission));
    }

    function delegatedFinish(address _p) {
        require(_p.delegatecall(bytes4(keccak256("finish()"))));
    }

    function countTokens(uint weiAmount, uint[] bonusPeriods, uint[] bonusRates, uint etherRate) constant returns (uint) {
        for (uint i = 0; i < bonusPeriods.length; i++) {
            if (now < bonusPeriods[i]) {
                etherRate = bonusRates[i];
                break;
            }
        }
        uint tokensAmount = weiAmount * etherRate;

        return tokensAmount;
    }

    function countRefundSum(uint tokensAmount, uint etherRate, uint newRate, uint multiplier) constant returns (uint) {
        uint fromPercentDivider = 100;

        return (tokensAmount / fromPercentDivider * newRate) / (multiplier * etherRate);
    }
}
