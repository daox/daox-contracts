"use strict";
const helper = require('../helpers/helper.js');
const Withdrawal = artifacts.require('./Votings/Refund.sol');
const Token = artifacts.require('./Token/Token.sol');

contract("Withdrawal", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const [teamPerson1, teamPerson2] = [accounts[2], accounts[3]];
    const [whiteListAddress1, whiteListAddress2] = [accounts[4], accounts[5]];
    const team = [teamPerson1, teamPerson2];
    const [backer1, backer2, backer3, backer4] = [accounts[6], accounts[7], accounts[8], accounts[9]];
    const teamBonuses = [8, 9];
    const withdrawalDuration = 300;
    let withdrawalSum = 1;

    let withdrawal, dao, cdf, timestamp;
    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf);
        await dao.initBonuses.sendTransaction(team, teamBonuses, [], [], [10000, 10000]);
        await dao.setWhiteList.sendTransaction([whiteListAddress1, whiteListAddress2]);
    });

    const makeDAOAndCreateWithdrawal = async (backersToWei, backersToOptions, withdrawalCreator, whiteListAddress, finish = true, shiftTime = false) => {
        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        const tx = await dao.addWithdrawal("Test description", withdrawalDuration, web3.toWei(withdrawalSum), whiteListAddress, {from : withdrawalCreator});
        const logs = helper.decodeVotingParameters(tx);
        withdrawal = Withdrawal.at(logs[0]);

        return makeWithdrawal(backersToOptions, finish, shiftTime);
    };

    const makeWithdrawal = async (backersToOptions, finish, shiftTime) => {
        timestamp = (await helper.getLatestBlock(web3)).timestamp;
        await Promise.all(Object.keys(backersToOptions).map(key => withdrawal.addVote.sendTransaction(backersToOptions[key], {from: key})));

        if (shiftTime) {
            await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration]);
            await helper.rpcCall(web3, "evm_mine", null);
        }
        if (finish) {
            return withdrawal.finish()
        }
    };

    it("Should add vote from 2 different accounts", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress1, true, true);

        const token = Token.at(await dao.token.call());

        const [option1, option2, holdTime1, holdTime2, isFinished, duration] = await Promise.all([
            withdrawal.options.call(1),
            withdrawal.options.call(2),
            token.held.call(backer1),
            token.held.call(backer2),
            withdrawal.finished.call(),
            withdrawal.duration.call()
        ]);

        assert.deepEqual(option1[0], option2[0], "Votes amount doesn't equal");
        assert.equal(timestamp + withdrawalDuration, holdTime1.toNumber(), "Hold time was not calculated correct");
        assert.deepEqual(holdTime1, holdTime2, "Tokens amount doesn't equal");
        assert.isTrue(isFinished, "Withdrawal was not cancelled");
        assert.equal(withdrawalDuration, duration, "Withdrawal duration is not correct");
    });

    it("Should not create withdrawal from unknown account", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        return helper.handleErrorTransaction(() => makeDAOAndCreateWithdrawal(backersToWei, backersToOption, unknownAccount, whiteListAddress2, true, true));
    });

    it("Should finish withdrawal when duration is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress2, true, true);

        const [option1, isFinished, result] = await Promise.all([
            withdrawal.options.call(1),
            withdrawal.finished.call(),
            withdrawal.result.call()
        ]);

        assert.deepEqual(option1, result, "Result is invalid");
        assert.isTrue(isFinished, "Withdrawal was not finished");
    });

    it("Should not finish withdrawal when time is not up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress2, false, false);

        return helper.handleErrorTransaction(() => withdrawal.finish.sendTransaction());
    });

    it("Should not add vote when time is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress2, false, true);

        return helper.handleErrorTransaction(() => withdrawal.addVote.sendTransaction(1, {from: backer2}));
    });

    it("Should not finish withdrawal twice", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress2, true, true);

        return helper.handleErrorTransaction(() => withdrawal.finish.sendTransaction());
    });

    it("Team member can't add vote", async () => {
        const backers = [backer1, backer2, teamPerson1];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether")
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;

        return helper.handleErrorTransaction(() => makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, whiteListAddress2, false, false));
    });

    it("Should not accept withdrawal when amount of votes for option#1 equals amount of votes for option#2", async () => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        for (let i = 0; i < backers.length; i++) {
            backersToWei[`${backers[i]}`] = web3.toWei(5, "ether");
            backersToOption[`${backers[i]}`] = i % 2 == 0 ? 1 : 2; // 10 eth (in tokens) for "yes" and 10 eth (in tokens) for "no"
        }

        await makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress2, true, true);

        const [option1, option2, isFinished, result] = await Promise.all([
            withdrawal.options.call(1),
            withdrawal.options.call(2),
            withdrawal.finished.call(),
            withdrawal.result.call()
        ]);

        assert.deepEqual(option1[0], option2[0]);
        assert.isTrue(isFinished);
        assert.deepEqual(option2, result);
    });

    it("Should accept withdrawal when 50% + 1 votes for option#1", async () => {
        const backers = [backer1, backer2, backer3];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[2]}`] = 1; // 1 wei
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;

        await makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress2, true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option1, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            withdrawal.options.call(1),
            withdrawal.result.call(),
            withdrawal.finished.call(),
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option1, result, "Withdrawal should be accepted");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "Withdrawal was not finished");
    });

    it("Should not create withdrawal with sum > dao.balance", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        withdrawalSum = 11; //greater then dao balance

        return helper.handleErrorTransaction(() => makeDAOAndCreateWithdrawal(backersToWei, backersToOption, backer1, whiteListAddress2, true, true));
    });
});