"use strict";
const helper = require('../helpers/helper.js');
const Withdrawal = artifacts.require('./Votings/Withdrawal.sol');
const Module = artifacts.require('./Votings/Module.sol');
const Proposal = artifacts.require('./Votings/Proposal.sol');
const Refund = artifacts.require('./Votings/Refund.sol');
const Token = artifacts.require('./Token/Token.sol');
const DXCToken = artifacts.require("./Token/DXC.sol");


contract("VotingDecisions", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const [teamPerson1, teamPerson2] = [accounts[2], accounts[3]];
    const team = [teamPerson1, teamPerson2];
    const [whiteListAddress1] = [accounts[4]];
    const [backer1, backer2, backer3, backer4, backer5] = [accounts[5], accounts[6], accounts[7], accounts[8], accounts[9]];
    const backers = [backer1, backer2, backer3, backer4, backer5];
    const teamBonuses = [9, 9];
    const minimalDurationPeriod = 60 * 60 * 24 * 7;
    const FOUR_MONTHS = 120 * 24 * 60 * 60;

    const Modules = {
        State: 0,
        Payment: 1,
        VotingDecisions: 2,
        Crowdsale: 3
    };

    let withdrawal, dao, cdf, timestamp, token, DXC;
    const backersToWei = {};
    backersToWei[backers[1]] = web3.toWei(2);
    backersToWei[backers[2]] = web3.toWei(3);
    backersToWei[backers[3]] = web3.toWei(4);
    backersToWei[backers[4]] = web3.toWei(10);

    const revertVotingDecisions = async (oldVotingDecisionsModule) => {
        const tx = await dao.addModule("Test description", minimalDurationPeriod, Modules.VotingDecisions, oldVotingDecisionsModule, {from: backer2});
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[3]}`] = 1;
        backersToOption[`${backers[4]}`] = 1;
        backersToOption[`${backers[0]}`] = 2;
        backersToOption[`${backers[2]}`] = 2;

        await helper.makeModule(backersToOption, true, true, module, minimalDurationPeriod, web3);
    };

    const revertPayment = async (oldPayment) => {
        const tx = await dao.addModule("Test description", minimalDurationPeriod, Modules.Payment, oldPayment, {from: backer2});
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[3]}`] = 1;
        backersToOption[`${backers[4]}`] = 1;
        backersToOption[`${backers[0]}`] = 2;
        backersToOption[`${backers[2]}`] = 2;

        await helper.makeModule(backersToOption, true, true, module, minimalDurationPeriod, web3);
    };

    before(async () => {
        cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf, accounts);

        DXC = DXCToken.at(DXCToken.address);
        await DXC.mint(backer1, web3.toWei(2));

        await dao.initBonuses.sendTransaction(team, teamBonuses, [], [], [], [10000, 10000], [false, false], {gasPrice: 0});
        await dao.setWhiteList.sendTransaction([whiteListAddress1], {gasPrice: 0});
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await Promise.all(Object.keys(backersToWei).map(address => dao.sendTransaction({
            from: address,
            value: backersToWei[address],
            gasPrice: 0
        })));

        await DXC.contributeTo.sendTransaction(dao.address, web3.toWei(2), {from: backer1, gasPrice: 0});

        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        token = Token.at(await dao.token.call());

        await dao.finish.sendTransaction({from: serviceAccount, gasPrice: 0});
    });

    it("Proposal#1: equal votes for 2 options", async () => {
        const tx = await dao.addProposal("Test description", minimalDurationPeriod, ["Option1", "Option2"], {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const proposal = Proposal.at(logs[0]);

        const backersToOption = {};
        backersToOption[backers[0]] = 1;
        backersToOption[backers[1]] = 1;
        backersToOption[backers[2]] = 2;

        await helper.makeProposal(backersToOption, true, true, proposal, minimalDurationPeriod, web3);

        assert.isTrue(await proposal.finished.call());
        assert.equal(0, (await proposal.result.call())[0].toNumber());
        assert.equal((await token.balanceOf.call(backer1)).toNumber() + (await token.balanceOf.call(backer2)).toNumber(), (await proposal.options.call(1))[0].toNumber());
        assert.equal((await token.balanceOf.call(backer3)).toNumber(), (await proposal.options.call(2))[0].toNumber());
    });

    it("Proposal#2: 0 votes white entire voting", async () => {
        const tx = await dao.addProposal("Test description", minimalDurationPeriod, ["Option1", "Option2"], {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const proposal = Proposal.at(logs[0]);

        const backersToOption = {};

        await helper.makeProposal(backersToOption, true, true, proposal, minimalDurationPeriod, web3);

        assert.isTrue(await proposal.finished.call());
        assert.equal(0, (await proposal.result.call())[0].toNumber());
    });

    it("Proposal#3: usual voting process", async () => {
        const tx = await dao.addProposal("Test description", minimalDurationPeriod, ["Option1", "Option2", "Option3"], {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const proposal = Proposal.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[2]}`] = 2;
        backersToOption[`${backers[3]}`] = 3;

        await helper.makeProposal(backersToOption, true, true, proposal, minimalDurationPeriod, web3);

        assert.isTrue(await proposal.finished.call());
        assert.deepEqual(await proposal.options.call(3), await proposal.result.call());
    });

    it("Module#1: should not accept module changing when amount of votes for option#1 < 80%", async () => {
        const tx = await dao.addModule("Test description", minimalDurationPeriod, Modules.State, "0x1", {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[4]}`] = 1;

        const moduleAddressBefore = await dao.stateModule.call();
        await helper.makeModule(backersToOption, true, true, module, minimalDurationPeriod, web3);

        assert.isTrue(await module.finished.call());
        assert.equal(moduleAddressBefore, await dao.stateModule.call());
        assert.equal(0, (await module.result.call())[0].toNumber());
    });

    it("Module#2: should not create module with invalid module name", async () =>
        helper.handleErrorTransaction(() => dao.addModule("Test description", minimalDurationPeriod, 4, "0x1", {from: backer1})));

    it("Module#3: should change state address when amount of votes for option#1 >= 80%", async () => {
        const tx = await dao.addModule("Test description", minimalDurationPeriod, Modules.State, unknownAccount, {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[3]}`] = 1;
        backersToOption[`${backers[4]}`] = 1;

        await helper.makeModule(backersToOption, true, true, module, minimalDurationPeriod, web3);

        assert.isTrue(await module.finished.call());
        assert.equal(unknownAccount, await dao.stateModule.call());
    });

    it("Module#4: should change crowdsale address when amount of votes for option#1 >= 80%", async () => {
        const tx = await dao.addModule("Test description", minimalDurationPeriod, Modules.Crowdsale, unknownAccount, {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[3]}`] = 1;
        backersToOption[`${backers[4]}`] = 1;
        backersToOption[`${backers[0]}`] = 2;
        backersToOption[`${backers[2]}`] = 2;

        await helper.makeModule(backersToOption, true, true, module, minimalDurationPeriod, web3);

        assert.isTrue(await module.finished.call());
        assert.equal(unknownAccount, await dao.crowdsaleModule.call());
    });

    it("Module#5: should change voting decisions address when amount of votes for option#1 >= 80%", async () => {
        const oldVotingDecisionsModule = await dao.votingDecisionModule.call();
        const tx = await dao.addModule("Test description", minimalDurationPeriod, Modules.VotingDecisions, unknownAccount, {from: backer2});
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[3]}`] = 1;
        backersToOption[`${backers[4]}`] = 1;
        backersToOption[`${backers[0]}`] = 2;
        backersToOption[`${backers[2]}`] = 2;

        await helper.makeModule(backersToOption, true, true, module, minimalDurationPeriod, web3);

        assert.isTrue(await module.finished.call());
        assert.equal(unknownAccount, await dao.votingDecisionModule.call());

        await revertVotingDecisions(oldVotingDecisionsModule);
    });

    it("Module#6: should change payment address when amount of votes for option#1 >= 80%", async () => {
        const oldPaymentModule = await dao.paymentModule.call();
        const tx = await dao.addModule("Test description", minimalDurationPeriod, Modules.Payment, unknownAccount, {from: backer2});
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[3]}`] = 1;
        backersToOption[`${backers[4]}`] = 1;
        backersToOption[`${backers[0]}`] = 2;
        backersToOption[`${backers[2]}`] = 2;

        await helper.makeModule(backersToOption, true, true, module, minimalDurationPeriod, web3);

        assert.isTrue(await module.finished.call());
        assert.equal(unknownAccount, await dao.paymentModule.call());

        await revertPayment(oldPaymentModule);
    });

    it("Withdrawal#1: should not be accepted when equal votes for 2 options. Withdrawal in eth", async () => {
        const withdrawalSum = web3.toWei(1);
        const tx = await dao.addWithdrawal("Test description", minimalDurationPeriod, withdrawalSum, whiteListAddress1, false, {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const withdrawal = Withdrawal.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[2]}`] = 2;

        let rpcResponse = await helper.rpcCall(web3, "eth_getBalance", [dao.address]);
        const balanceBefore = web3.fromWei(rpcResponse.result);

        await helper.makeWithdrawal(backersToOption, true, true, withdrawal, minimalDurationPeriod, web3);

        rpcResponse = await helper.rpcCall(web3, "eth_getBalance", [dao.address]);
        const balanceAfter = web3.fromWei(rpcResponse.result);

        assert.isTrue(await withdrawal.finished.call());
        assert.deepEqual(await withdrawal.options.call(2), await withdrawal.result.call());
        assert.equal(balanceBefore, balanceAfter);
    });

    it("Withdrawal#2: should be accepted when >=50% votes for option#1. Withdrawal in eth", async () => {
        const withdrawalSum = web3.toWei(1);
        const tx = await dao.addWithdrawal("Test description", minimalDurationPeriod, withdrawalSum, whiteListAddress1, false, {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const withdrawal = Withdrawal.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[0]}`] = 2;
        backersToOption[`${backers[1]}`] = 1;

        const balanceBefore = await helper.getBalance(web3, dao.address);

        await helper.makeWithdrawal(backersToOption, true, true, withdrawal, minimalDurationPeriod, web3);

        const balanceAfter = await helper.getBalance(web3, dao.address);

        assert.isTrue(await withdrawal.finished.call());
        assert.deepEqual(await withdrawal.options.call(1), await withdrawal.result.call());
        assert.equal(balanceBefore - web3.fromWei(withdrawalSum), balanceAfter);
    });

    it("Withdrawal#3: should be accepted when >=50% votes for option#1. Withdrawal in DXC", async () => {
        const withdrawalSum = 2; //2 dxt tokens
        const tx = await dao.addWithdrawal("Test description", minimalDurationPeriod, withdrawalSum, whiteListAddress1, true, {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const withdrawal = Withdrawal.at(logs[0]);

        const backersToOption = {};
        backersToOption[backers[0]] = 2;
        backersToOption[backers[1]] = 1;

        const [daoBalanceBefore, whiteListBalanceBefore] = await Promise.all([
            DXC.balanceOf.call(dao.address),
            DXC.balanceOf.call(whiteListAddress1)
        ]);

        await helper.makeWithdrawal(backersToOption, true, true, withdrawal, minimalDurationPeriod, web3);

        const [daoBalanceAfter, whiteListBalanceAfter] = await Promise.all([
            DXC.balanceOf.call(dao.address),
            DXC.balanceOf.call(whiteListAddress1)
        ]);

        assert.isTrue(await withdrawal.finished.call());
        assert.deepEqual(await withdrawal.options.call(1), await withdrawal.result.call());
        assert.equal(daoBalanceBefore.toNumber() - withdrawalSum, daoBalanceAfter.toNumber());
        assert.equal(whiteListBalanceBefore.toNumber() + withdrawalSum, whiteListBalanceAfter.toNumber());
    });

    it("Refund#1: should be not accepted when <90% votes for option#1", async () => {
        const withdrawalSum = web3.toWei(1);
        const tx = await dao.addRefund("Test description", minimalDurationPeriod, {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const refund = Refund.at(logs[0]);

        const backersToOption = {};
        backersToOption[`${backers[4]}`] = 1;

        await helper.makeRefund(backersToOption, true, true, refund, minimalDurationPeriod, web3);

        assert.isTrue(await refund.finished.call());
        assert.deepEqual(await refund.options.call(2), await refund.result.call());
        assert.isNotTrue(await dao.refundable.call());
    });

    it("Refund#2: should be accepted when >=90% votes for option#1", async () => {
        const tx = await dao.addRefund("Test description", minimalDurationPeriod, {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const refund = Refund.at(logs[0]);
        const DXCRate = 500;

        const backersToOption = {};
        backersToOption[backers[0]] = 1;
        backersToOption[backers[2]] = 1;
        backersToOption[backers[3]] = 1;
        backersToOption[backers[4]] = 1;

        await helper.makeRefund(backersToOption, true, true, refund, minimalDurationPeriod, web3);
        const [daoBalanceBefore, weiRaised] = await Promise.all([
            helper.getBalance(web3, dao.address),
            dao.weiRaised.call()
        ]);

        const newEtherRate = (await dao.newEtherRate.call()).toNumber() / 100000;
        const newDXCRate = await dao.newDXCRate.call();
        assert.isTrue(await refund.finished.call());
        assert.deepEqual(await refund.options.call(1), await refund.result.call());
        assert.isTrue(await dao.refundable.call());
        assert.equal((daoBalanceBefore / web3.fromWei(weiRaised).toNumber()).toFixed(4), newEtherRate.toFixed(4));

        const [backer1EtherBalanceBefore, backer2EtherBalanceBefore, backer3EtherBalanceBefore, backer4EtherBalanceBefore, backer5EtherBalanceBefore] = await Promise.all([
            helper.getBalance(web3, backer1),
            helper.getBalance(web3, backer2),
            helper.getBalance(web3, backer3),
            helper.getBalance(web3, backer4),
            helper.getBalance(web3, backer5)
        ]);
        const [backer1Tokens, backer2Tokens, backer3Tokens, backer4Tokens, backer5Tokens] = await Promise.all([
            token.balanceOf.call(backer1),
            token.balanceOf.call(backer2),
            token.balanceOf.call(backer3),
            token.balanceOf.call(backer4),
            token.balanceOf.call(backer5),
        ]);

        await Promise.all([
            dao.refund.sendTransaction({from: backer1, gasPrice: 0}),
            dao.refund.sendTransaction({from: backer2, gasPrice: 0}),
            dao.refund.sendTransaction({from: backer3, gasPrice: 0}),
            dao.refund.sendTransaction({from: backer4, gasPrice: 0}),
            dao.refund.sendTransaction({from: backer5, gasPrice: 0})
        ]);

        const [tokenMintedByEther, tokenMintedByDXC] = await Promise.all([
            dao.tokenMintedByEther.call(),
            dao.tokenMintedByDXC.call()
        ]);

        const etherPerDXCRate = tokenMintedByEther.toNumber() / (tokenMintedByEther.toNumber() + tokenMintedByDXC.toNumber());
        const dxtPerEtherRate = tokenMintedByDXC.toNumber() / (tokenMintedByEther.toNumber() + tokenMintedByDXC.toNumber());

        assert.isTrue(helper.doesApproximatelyEqual(parseFloat(backer1EtherBalanceBefore) + parseFloat(newEtherRate * etherPerDXCRate), parseFloat(await helper.getBalance(web3, backer1))));
        assert.isTrue(helper.doesApproximatelyEqual(parseFloat(backer2EtherBalanceBefore) + web3.fromWei(backersToWei[backer2]) * newEtherRate * etherPerDXCRate, parseFloat(await helper.getBalance(web3, backer2))));
        assert.isTrue(helper.doesApproximatelyEqual(parseFloat(backer3EtherBalanceBefore) + web3.fromWei(backersToWei[backer3]) * newEtherRate * etherPerDXCRate, parseFloat(await helper.getBalance(web3, backer3))));
        assert.isTrue(helper.doesApproximatelyEqual(parseFloat(backer4EtherBalanceBefore) + web3.fromWei(backersToWei[backer4]) * newEtherRate * etherPerDXCRate, parseFloat(await helper.getBalance(web3, backer4))));
        assert.isTrue(helper.doesApproximatelyEqual(parseFloat(backer5EtherBalanceBefore) + web3.fromWei(backersToWei[backer5]) * newEtherRate * etherPerDXCRate, parseFloat(await helper.getBalance(web3, backer5))));

        assert.equal(parseFloat(web3.fromWei( backer1Tokens * dxtPerEtherRate * newDXCRate / (100000 * DXCRate))).toFixed(6), web3.fromWei(await DXC.balanceOf.call(backer1)).toNumber().toFixed(6));
        assert.equal(parseFloat(web3.fromWei( backer2Tokens * dxtPerEtherRate * newDXCRate / (100000 * DXCRate))).toFixed(6), web3.fromWei(await DXC.balanceOf.call(backer2)).toNumber().toFixed(6));
        assert.equal(parseFloat(web3.fromWei( backer3Tokens * dxtPerEtherRate * newDXCRate / (100000 * DXCRate))).toFixed(6), web3.fromWei(await DXC.balanceOf.call(backer3)).toNumber().toFixed(6));
        assert.equal(parseFloat(web3.fromWei( backer4Tokens * dxtPerEtherRate * newDXCRate / (100000 * DXCRate))).toFixed(6), web3.fromWei(await DXC.balanceOf.call(backer4)).toNumber().toFixed(6));
        assert.equal(parseFloat(web3.fromWei( backer5Tokens * dxtPerEtherRate * newDXCRate / (100000 * DXCRate))).toFixed(6), web3.fromWei(await DXC.balanceOf.call(backer5)).toNumber().toFixed(6));
    });

    it("Make refundable by user#1: should not become refundable when soft cap reached", async () => {
        const cdf = await helper.createCrowdsaleDAOFactory();
        const dao = await helper.createCrowdsaleDAO(cdf, accounts);
        await dao.initBonuses.sendTransaction(team, teamBonuses, [], [], [], [10000, 10000], [false, false]);
        await dao.setWhiteList.sendTransaction([whiteListAddress1]);
        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        assert.isNotTrue(await dao.refundable.call());

        return helper.handleErrorTransaction(() => dao.makeRefundableByUser.sendTransaction({from: backer4}));
    });

    it("Make refundable by user#2: should become refundable when last withdrawal was >= 4 months ago", async () => {
        const cdf = await helper.createCrowdsaleDAOFactory();
        const dao = await helper.createCrowdsaleDAO(cdf, accounts);
        await dao.initBonuses.sendTransaction(team, teamBonuses, [], [], [], [10000, 10000], [false, false]);
        await dao.setWhiteList.sendTransaction([whiteListAddress1]);
        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        assert.isNotTrue(await dao.refundable.call());

        await helper.rpcCall(web3, "evm_increaseTime", [FOUR_MONTHS]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.makeRefundableByUser.sendTransaction({from: backer4});

        assert.isTrue(await dao.refundable.call());
    });
});
