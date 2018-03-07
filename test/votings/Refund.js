"use strict";
const helper = require('../helpers/helper.js');
const Refund = artifacts.require('./Votings/Refund.sol');
const Token = artifacts.require('./Token/Token.sol');

contract("Refund", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const [teamPerson1, teamPerson2, teamPerson3, teamPerson4] = [accounts[2], accounts[3], accounts[4], accounts[5]];
    const team = [teamPerson1, teamPerson2, teamPerson3, teamPerson4];
    const [backer1, backer2, backer3, backer4] = [accounts[6], accounts[7], accounts[8], accounts[9]];
    const teamBonuses = [2, 2, 2, 5];
    const refundDuration = 300;

    let refund, dao, cdf, timestamp;
    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf);
        await dao.initBonuses.sendTransaction(team, teamBonuses, [], [], [], [10000, 10000, 10000, 10000]);
    });

    const makeDAOAndCreateRefund = async (backersToWei, backersToOptions, refundCreator, finish = true, shiftTime = false) => {
        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        const tx = await dao.addRefund('Test description', refundDuration, {from : refundCreator});
        const logs = helper.decodeVotingParameters(tx);
        refund = Refund.at(logs[0]);

        return makeRefund(backersToOptions, finish, shiftTime);
    };

    const makeRefund = async (backersToOptions, finish, shiftTime) => {
        timestamp = (await helper.getLatestBlock(web3)).timestamp;
        await Promise.all(Object.keys(backersToOptions).map(key => refund.addVote.sendTransaction(backersToOptions[key], {from: key})));

        if (shiftTime) {
            await helper.rpcCall(web3, "evm_increaseTime", [refundDuration]);
            await helper.rpcCall(web3, "evm_mine", null);
        }
        if (finish) {
            return refund.finish()
        }
    };

    it("Should add vote from 2 different accounts", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, false, false);

        const token = Token.at(await dao.token.call());

        const [option1, option2, holdTime1, holdTime2, isFinished, duration] = await Promise.all([
            refund.options.call(1),
            refund.options.call(2),
            token.held.call(backer1),
            token.held.call(backer2),
            refund.finished.call(),
            refund.duration.call()
        ]);

        assert.deepEqual(option1[0], option2[0], "Votes amount doesn't equal");
        assert.equal(timestamp + refundDuration, holdTime1.toNumber(), "Hold time was not calculated correct");
        assert.deepEqual(holdTime1, holdTime2, "Tokens amount doesn't equal");
        assert.isNotTrue(isFinished, "Refund was cancelled");
        assert.equal(refundDuration, duration, "Refund duration is not correct");
    });

    it("Should not create refund from unknown account", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        return helper.handleErrorTransaction(() => makeDAOAndCreateRefund(backersToWei, backersToOption, unknownAccount, true, true));
    });

    it("Should finish refund when duration is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, true, true);

        const [option1, isFinished, result] = await Promise.all([
            refund.options.call(1),
            refund.finished.call(),
            refund.result.call()
        ]);

        assert.deepEqual(option1, result, "Result is invalid");
        assert.isTrue(isFinished, "Refund was not finished");
    });

    it("Should not finish refund when time is not up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, false, false);

        return helper.handleErrorTransaction(() => refund.finish.sendTransaction());
    });

    it("Should not add vote when time is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, false, true);

        return helper.handleErrorTransaction(() => refund.addVote.sendTransaction(1, {from: backer1}));
    });

    it("Should not finish refund twice", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, true, true);

        return helper.handleErrorTransaction(() => refund.finish.sendTransaction());
    });

    it("Should not accept refund when amount of votes for option#1 equals amount of votes for option#2", async () => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        for (let i = 0; i < backers.length; i++) {
            backersToWei[`${backers[i]}`] = web3.toWei(5, "ether");
            backersToOption[`${backers[i]}`] = i % 2 == 0 ? 1 : 2; // 10 eth (in tokens) for "yes" and 10 eth (in tokens) for "no"
        }

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, true, true);

        const [option1, option2, isFinished, result] = await Promise.all([
            refund.options.call(1),
            refund.options.call(2),
            refund.finished.call(),
            refund.result.call()
        ]);

        assert.deepEqual(option1[0], option2[0]);
        assert.isTrue(isFinished);
        assert.deepEqual(option2, result);
    });

    it("Team member can't add vote", async () => {
        const backers = [backer1, backer2, teamPerson1];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether")
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;

        return helper.handleErrorTransaction(() => makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, false, false));
    });

    it("Should not accept refund when amount of votes for option#1 is less then 90%", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(8.9, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(1.1, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option2, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            refund.options.call(2),
            refund.result.call(),
            refund.finished.call()
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option2, result, "Refund was not cancelled");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "Refund was not finished");
    });

    it("Should accept refund when amount of votes for option#1 is greater then 90%", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(18, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(2, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option1, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            refund.options.call(1),
            refund.result.call(),
            refund.finished.call()
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option1, result, "Refund was not cancelled");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "Refund was not finished");
    });
});