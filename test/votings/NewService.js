"use strict";
const helper = require('../helpers/helper.js');
const NewService = artifacts.require('./Votings/Service/NewService.sol');
const Token = artifacts.require('./Token/Token.sol');
const ExampleService = artifacts.require('./DAO/API/ExampleService.sol');
const DXC = artifacts.require("./Token/DXC.sol");
const ProxyAPI = artifacts.require("./DAO/API/ProxyAPI.sol");

contract("New Service", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const [teamPerson1, teamPerson2] = [accounts[4], accounts[5]];
    const teamBonuses = [5, 5];
    const [backer1, backer2, backer3, backer4] = [accounts[6], accounts[7], accounts[8], accounts[9]];
    const minimalDurationPeriod = 60 * 60 * 24 * 7;

    const name = "Change newService voting";
    let newService, dao, cdf, timestamp;
    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf, accounts);
        await dao.initBonuses.sendTransaction([teamPerson1, teamPerson2], teamBonuses, [], [], [], [10000, 10000], [false, false]);
    });

    const makeDAOAndCreateNewService = async (backersToWei, backersToOptions, creator, finish = true, shiftTime = false, serviceAddress = ExampleService.address) => {
        await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

        await helper.payForVoting(dao, creator);
        const tx = await dao.addNewService(name, "", minimalDurationPeriod, serviceAddress, {from: creator});
        const logs = helper.decodeVotingParameters(tx);
        newService = NewService.at(logs[0]);

        return makeNewService(backersToOptions, finish, shiftTime);
    };

    const makeNewService = async (backersToOptions, finish, shiftTime) => {
        timestamp = (await helper.getLatestBlock(web3)).timestamp;
        await Promise.all(Object.keys(backersToOptions).map(key => newService.addVote.sendTransaction(backersToOptions[key], {from: key})));

        if (shiftTime) {
            await helper.rpcCall(web3, "evm_increaseTime", [minimalDurationPeriod]);
            await helper.rpcCall(web3, "evm_mine", null);
        }
        if (finish) {
            return newService.finish()
        }
    };

    it("Should add vote from 2 different accounts", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, false, true);

        const token = Token.at(await dao.token.call());

        const [option1, option2, holdTime1, holdTime2, isFinished, duration] = await Promise.all([
            newService.options.call(1),
            newService.options.call(2),
            token.held.call(backer1),
            token.held.call(backer2),
            newService.finished.call(),
            newService.duration.call()
        ]);

        assert.deepEqual(option1[0], option2[0], "Votes amount doesn't equal");
        assert.equal(timestamp + minimalDurationPeriod, holdTime1.toNumber(), "Hold time was not calculated correct");
        assert.deepEqual(holdTime1, holdTime2, "Tokens amount doesn't equal");
        assert.isFalse(isFinished, "Module was not cancelled");
        assert.equal(minimalDurationPeriod, duration, "Module duration is not correct");
    });

    it("Should not create newService from unknown account", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        return helper.handleErrorTransaction(() => makeDAOAndCreateNewService(backersToWei, backersToOption, unknownAccount,  true, true));
    });

    it("Should finish newService when duration is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, false, true);
        const initialCapitalBefore = await dao.initialCapital();
        await newService.finish.sendTransaction();

        const [option1, isFinished, result, initialCapitalAfter] = await Promise.all([
            newService.options.call(1),
            newService.finished.call(),
            newService.result.call(),
            dao.initialCapital()
        ]);

        const service = ExampleService.at(ExampleService.address);

        assert.deepEqual(option1, result, "Result is invalid");
        assert.isTrue(isFinished, "Module was not finished");
        assert.isTrue(await dao.services(ExampleService.address));
        assert.isTrue(await service.daos(dao.address));
        assert.deepEqual(initialCapitalBefore, initialCapitalAfter.plus(await service.priceToConnect()));
    });

    it("Should not finish newService when time is not up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, false, false);

        return helper.handleErrorTransaction(() => newService.finish.sendTransaction());
    });

    it("Should not add vote when time is up", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1,  false, true);

        return helper.handleErrorTransaction(() => newService.addVote.sendTransaction(1, {from: backer2}));
    });

    it("Should not finish newService twice", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true);

        return helper.handleErrorTransaction(() => newService.finish.sendTransaction());
    });

    it("Team member can't add vote", async () => {
        const backers = [backer1, backer2, teamPerson1];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;

        return helper.handleErrorTransaction(() => makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, false, false));
    });

    it("Should not accept newService when amount of votes for option#1 equals amount of votes for option#2", async () => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        for (let i = 0; i < backers.length; i++) {
            backersToWei[`${backers[i]}`] = web3.toWei(5, "ether");
            backersToOption[`${backers[i]}`] = i % 2 === 0 ? 1 : 2; // 10 eth (in tokens) for "yes" and 10 eth (in tokens) for "no"
        }

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1,  true, true);

        const [option1, option2, isFinished, result] = await Promise.all([
            newService.options.call(1),
            newService.options.call(2),
            newService.finished.call(),
            newService.result.call()
        ]);

        assert.deepEqual(option1[0], option2[0]);
        assert.isTrue(isFinished);
        assert.deepEqual(option2, result);
    });

    it("Should not accept newService when 50% + 1 votes for option#1", async () => {
        const backers = [backer1, backer2, backer3];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[2]}`] = 1; // 1 wei
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1,  true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option2, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            newService.options.call(2),
            newService.result.call(),
            newService.finished.call(),
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option2, result, "Module should not be accepted");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "Module was not finished");
    });

    it("Should accept newService when 80% votes for option#1", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(8, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(2, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option1, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            newService.options.call(1),
            newService.result.call(),
            newService.finished.call(),
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option1, result, "New Service should be accepted");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "New Service was not finished");
    });

    it("Should not create newService voting if initial capital is less than service price", async () => {
        const backers = [backer1, backer2];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(8, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(2, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;

        const service = await ExampleService.new(web3.toWei(2), 0, DXC.address, ProxyAPI.address);
        await helper.payForVoting(dao, accounts[0]);
        return helper.handleErrorTransaction(() => makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true, service.address));
    });

    it("Should not let create proposal if not enough DXC for voting price was transferred", async () => {
        const dxc = await helper.mintDXC(accounts[0], web3.toWei('0.09'));
        await dxc.contributeTo.sendTransaction(dao.address, web3.toWei('0.09'));

        return helper.handleErrorTransaction(() => dao.addNewService(name, "", minimalDurationPeriod, ExampleService.address, {from: accounts[0]}));
    });

    it("Should not let create proposal if not enough DXC for voting price was transferred", async () => {
        await helper.payForVoting(dao, accounts[9]);

        return helper.handleErrorTransaction(() => dao.addNewService(name, "", minimalDurationPeriod, ExampleService.address, {from: accounts[9]}));
    });
});