"use strict";
const helper = require('../helpers/helper.js');
const Refund = artifacts.require('./Votings/Refund.sol');
const Token = artifacts.require('./Token/Token.sol');

contract("Refund", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const [whiteListPerson1, whiteListPerson2, whiteListPerson3, whiteListPerson4] = [accounts[2], accounts[3], accounts[4], accounts[5]];
    const [backer1, backer2, backer3, backer4] = [accounts[6], accounts[7], accounts[8], accounts[9]];
    const refundDuration = 300;

    let refund, dao, cdf;
    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf);
        await dao.setWhiteList.sendTransaction([whiteListPerson1, whiteListPerson2, whiteListPerson3, whiteListPerson4]);
    });

    const makeDAOAndCreateRefund = async (backersToWei, backersToOptions, refundCreator, finish = true, shiftTime = false) => {
        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        const tx = await dao.addRefund('Test description', refundDuration, {from : refundCreator});
        const logs = helper.decodeVotingParameters(tx);
        refund = Refund.at(logs[0]);

        return makeRefund(backersToOptions, finish, shiftTime);
    };

    const makeRefund = async (backersToOptions, finish, shiftTime) => {
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
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether")
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, false, false);

        const token = Token.at(await dao.token.call());

        const [option1, option2, balance1, balance2, isFinished] = await Promise.all([
            refund.options.call(1),
            refund.options.call(2),
            token.balanceOf.call(backer1),
            token.balanceOf.call(backer2),
            refund.finished.call()
        ]);

        assert.deepEqual(option1[0], option2[0], "Votes amount doesn't equal");
        assert.deepEqual(balance1, balance2, "Tokens amount doesn't equal");
        assert.isNotTrue(isFinished);
    });

    it("Should not create refund from unknown account", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether")
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        return helper.handleErrorTransaction(() => makeDAOAndCreateRefund(backersToWei, backersToOption, unknownAccount, true, true));
    });

    it("Should finish refund when duration is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether")
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

    // it("Should not accept refund when amount of votes for option#1 equals amount of votes for option#2", async () => {
    //     const backers = [backer1, backer2, backer3, backer4];
    //     const [backersToWei, backersToOption] = [{}, {}];
    //     for (let i = 0; i < backers.length; i++) {
    //         backersToWei[`${backers[i]}`] = web3.toWei(5, "ether");
    //         backersToOption[`${backers[i]}`] = i % 2 == 0 ? 1 : 2; // 10 eth (in tokens) for "yes" and 10 eth (in tokens) for "no"
    //     }
    //
    //     console.log(backersToWei);
    //     await makeDAOAndCreateRefund(backersToWei, backersToOption, backer1, true, true);

        // const [option1, option2, balance1, isFinished, result] = await Promise.all([
        //     refund.options.call(1),
        //     refund.options.call(2),
        //     refund.finished.call(),
        //     refund.result.call()
        // ]);
        //
        // console.log(option1[0]);
        // console.log(option2[0]);
        //
        // assert.equal(option1[0], option2[0]);
        // assert.isTrue(isFinished);
        // assert.deepEqual(option2, result);
    // });
});