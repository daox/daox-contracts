"use strict";
const helper = require('../helpers/helper.js');
const Module = artifacts.require('./Votings/Module.sol');
const Token = artifacts.require('./Token/Token.sol');

contract("Module", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const [newModuleAddress1, newModuleAddress2] = [accounts[2], accounts[3]];
    const [teamPerson1, teamPerson2] = [accounts[4], accounts[5]];
    const teamBonuses = [5, 5];
    const [backer1, backer2, backer3, backer4] = [accounts[6], accounts[7], accounts[8], accounts[9]];
    const minimalDurationPeriod = 60 * 60 * 24 * 7;
    const Modules = {
        State: 0,
        Payment: 1,
        VotingDecisions: 2,
        Crowdsale: 3
    };

    const name = "Change Module voting";
    let module, dao, cdf, timestamp;
    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf);
        await dao.initBonuses.sendTransaction([teamPerson1, teamPerson2], teamBonuses, [], [], [], [10000, 10000], [false, false]);
    });

    const makeDAOAndCreateModule = async (backersToWei, backersToOptions, creator, moduleName, newModuleAddress, finish = true, shiftTime = false) => {
        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        const tx = await dao.addModule(name, "Test description", minimalDurationPeriod, moduleName, newModuleAddress, {from: creator});
        const logs = helper.decodeVotingParameters(tx);
        module = Module.at(logs[0]);

        return makeModule(backersToOptions, finish, shiftTime);
    };

    const makeModule = async (backersToOptions, finish, shiftTime) => {
        timestamp = (await helper.getLatestBlock(web3)).timestamp;
        await Promise.all(Object.keys(backersToOptions).map(key => module.addVote.sendTransaction(backersToOptions[key], {from: key})));

        if (shiftTime) {
            await helper.rpcCall(web3, "evm_increaseTime", [minimalDurationPeriod]);
            await helper.rpcCall(web3, "evm_mine", null);
        }
        if (finish) {
            return module.finish()
        }
    };

    it("Should add vote from 2 different accounts", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.State, newModuleAddress1, true, true);

        const token = Token.at(await dao.token.call());

        const [option1, option2, holdTime1, holdTime2, isFinished, duration] = await Promise.all([
            module.options.call(1),
            module.options.call(2),
            token.held.call(backer1),
            token.held.call(backer2),
            module.finished.call(),
            module.duration.call()
        ]);

        assert.deepEqual(option1[0], option2[0], "Votes amount doesn't equal");
        assert.equal(timestamp + minimalDurationPeriod, holdTime1.toNumber(), "Hold time was not calculated correct");
        assert.deepEqual(holdTime1, holdTime2, "Tokens amount doesn't equal");
        assert.isTrue(isFinished, "Module was not cancelled");
        assert.equal(minimalDurationPeriod, duration, "Module duration is not correct");
    });

    it("Should not create module from unknown account", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        return helper.handleErrorTransaction(() => makeDAOAndCreateModule(backersToWei, backersToOption, unknownAccount, Modules.State, newModuleAddress2, true, true));
    });

    it("Should finish module when duration is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.VotingDecisions, newModuleAddress2, true, true);

        const [option1, isFinished, result] = await Promise.all([
            module.options.call(1),
            module.finished.call(),
            module.result.call()
        ]);

        assert.deepEqual(option1, result, "Result is invalid");
        assert.isTrue(isFinished, "Module was not finished");
    });

    it("Should not finish module when time is not up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.Crowdsale, newModuleAddress2, false, false);

        return helper.handleErrorTransaction(() => module.finish.sendTransaction());
    });

    it("Should not add vote when time is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.State, newModuleAddress2, false, true);

        return helper.handleErrorTransaction(() => module.addVote.sendTransaction(1, {from: backer2}));
    });

    it("Should not finish module twice", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.Crowdsale, newModuleAddress2, true, true);

        return helper.handleErrorTransaction(() => module.finish.sendTransaction());
    });

    it("Team member can't add vote", async () => {
        const backers = [backer1, backer2, teamPerson1];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether")
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;

        return helper.handleErrorTransaction(() => makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.State, newModuleAddress1, false, false));
    });

    it("Should not accept module when amount of votes for option#1 equals amount of votes for option#2", async () => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        for (let i = 0; i < backers.length; i++) {
            backersToWei[`${backers[i]}`] = web3.toWei(5, "ether");
            backersToOption[`${backers[i]}`] = i % 2 === 0 ? 1 : 2; // 10 eth (in tokens) for "yes" and 10 eth (in tokens) for "no"
        }

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.State, newModuleAddress2, true, true);

        const [option1, option2, isFinished, result] = await Promise.all([
            module.options.call(1),
            module.options.call(2),
            module.finished.call(),
            module.result.call()
        ]);

        assert.deepEqual(option1[0], option2[0]);
        assert.isTrue(isFinished);
        assert.deepEqual(option2, result);
    });

    it("Should not accept module when 50% + 1 votes for option#1", async () => {
        const backers = [backer1, backer2, backer3];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[2]}`] = 1; // 1 wei
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.State, newModuleAddress2, true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option2, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            module.options.call(2),
            module.result.call(),
            module.finished.call(),
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option2, result, "Module should not be accepted");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "Module was not finished");
    });

    it("Should accept module when 80% votes for option#1", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(8, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(2, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, Modules.State, newModuleAddress2, true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option1, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            module.options.call(1),
            module.result.call(),
            module.finished.call(),
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option1, result, "Module should be accepted");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "Module was not finished");
    });

    it("Should not create unknown module", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(8, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(2, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        return helper.handleErrorTransaction(() => makeDAOAndCreateModule(backersToWei, backersToOption, backer1, 5, newModuleAddress2, true, true));
    });

    it("Should change voting factory address", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(8, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(2, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        const oldVotingFactory = await dao.votingFactory();
        const newVF = "0x555";

        await makeDAOAndCreateModule(backersToWei, backersToOption, backer1, 4, newVF, true, true);

        assert.equal(`0x${web3.padLeft(newVF.replace("0x", ""), 40)}`, await dao.votingFactory());
    });

    it("Should create module when duration < minimal duration", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[backers[0]] = web3.toWei(8, "ether");
        backersToWei[backers[1]] = web3.toWei(2, "ether");
        backersToOption[backers[0]] = 1;
        backersToOption[backers[1]] = 2;

        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        const tx = await dao.addModule(name, "Test description", 0, 4, "0x1", {from: backers[0]});
        const logs = helper.decodeVotingParameters(tx);
        module = Module.at(logs[0]);

        assert.deepEqual(web3.toBigNumber(0), await module.duration());
    });
});