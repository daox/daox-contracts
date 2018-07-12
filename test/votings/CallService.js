"use strict";
const helper = require('../helpers/helper.js');
const NewService = artifacts.require('./Votings/Service/NewService.sol');
const CallService = artifacts.require('./Votings/Service/CallService.sol');
const Token = artifacts.require('./Token/Token.sol');
const ExampleService = artifacts.require('./DAO/API/ExampleService.sol');
const DXC = artifacts.require("./Token/DXC.sol");
const ProxyAPI = artifacts.require("./DAO/API/ProxyAPI.sol");
let TypesConverter = artifacts.require("./DAO/API/TypesConverter.sol");
TypesConverter = TypesConverter.at(TypesConverter.address);

contract("Call Service", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const [teamPerson1, teamPerson2] = [accounts[4], accounts[5]];
    const teamBonuses = [5, 5];
    const [backer1, backer2, backer3, backer4] = [accounts[6], accounts[7], accounts[8], accounts[9]];
    const minimalDurationPeriod = 60 * 60 * 24 * 7;

    const name = "Change newService voting";
    let newService, dao, cdf, timestamp, callService;
    const multiplier = 15;

    const makeDAOAndCreateNewService = async (backersToWei, backersToOptions, creator, finish = true, shiftTime = false, serviceAddress = ExampleService.address) => {
        if(serviceAddress === ExampleService.address) await helper.makeCrowdsaleNew(web3, cdf, dao, serviceAccount, backersToWei);

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

    const getBakers = (ether = [], options = []) => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(ether[0] || 5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(ether[0] || 5, "ether");
        backersToWei[`${backers[2]}`] = web3.toWei(ether[0] || 5, "ether");
        backersToWei[`${backers[3]}`] = web3.toWei(ether[0] || 5, "ether");
        backersToOption[`${backers[0]}`] = options[0] || 1;
        backersToOption[`${backers[1]}`] = options[0] || 1;
        backersToOption[`${backers[2]}`] = options[0] || 1;
        backersToOption[`${backers[3]}`] = options[0] || 1;

        return [backersToWei, backersToOption];
    };

    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf, accounts);
        await dao.initBonuses.sendTransaction([teamPerson1, teamPerson2], teamBonuses, [], [], [], [10000, 10000], [false, false]);
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = getBakers();

        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true);
    });

    const createCallService = async (creator, service) => {
        const bytes32Multiplier = await TypesConverter.uintToBytes32(multiplier);
        const args = [bytes32Multiplier, web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null)];
        return dao.addCallService(name, "Test Description", minimalDurationPeriod, service, web3.toHex("changeVotingPrice"), args, {from: creator});
    };

    const makeDAOAndCreateCallService = async (backersToWei, backersToOptions, creator, finish = true, shiftTime = false, serviceAddress = ExampleService.address) => {
        await helper.payForVoting(dao, creator);
        const tx = await createCallService(creator, serviceAddress);
        const logs = helper.decodeVotingParameters(tx);
        callService = CallService.at(logs[0]);

        return makeCallService(backersToOptions, finish, shiftTime);
    };

    const makeCallService = async (backersToOptions, finish, shiftTime) => {
        timestamp = (await helper.getLatestBlock(web3)).timestamp;
        await Promise.all(Object.keys(backersToOptions).map(key => callService.addVote.sendTransaction(backersToOptions[key], {from: key})));

        if (shiftTime) {
            await helper.rpcCall(web3, "evm_increaseTime", [minimalDurationPeriod]);
            await helper.rpcCall(web3, "evm_mine", null);
        }
        if (finish) {
            return callService.finish()
        }
    };

    it("Should add vote from 2 different accounts", async () => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[2]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[3]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[2]}`] = 2;
        backersToOption[`${backers[3]}`] = 2;

        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, false, true);

        const token = Token.at(await dao.token.call());

        const [option1, option2, holdTime1, holdTime2, isFinished, duration] = await Promise.all([
            callService.options.call(1),
            callService.options.call(2),
            token.held.call(backer1),
            token.held.call(backer2),
            callService.finished.call(),
            callService.duration.call()
        ]);

        assert.deepEqual(option1[0], option2[0], "Votes amount doesn't equal");
        assert.equal(timestamp + minimalDurationPeriod, holdTime1.toNumber(), "Hold time was not calculated correct");
        assert.deepEqual(holdTime1, holdTime2, "Tokens amount doesn't equal");
        assert.isFalse(isFinished, "Module was not cancelled");
        assert.equal(minimalDurationPeriod, duration, "Module duration is not correct");
    });

    it("Should not create callService from unknown account", async () => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToWei[`${backers[0]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[1]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[2]}`] = web3.toWei(5, "ether");
        backersToWei[`${backers[3]}`] = web3.toWei(5, "ether");
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 1;
        backersToOption[`${backers[2]}`] = 2;
        backersToOption[`${backers[3]}`] = 2;

        return helper.handleErrorTransaction(() => makeDAOAndCreateCallService(backersToWei, backersToOption, unknownAccount,  true, true));
    });

    it("Should finish callService when duration is up", async () => {
        const [backersToWei, backersToOption] = getBakers();

        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, false, true);
        const votingPriceBefore = await dao.votingPrice();
        await callService.finish.sendTransaction();

        const [option1, isFinished, result, votingPriceAfter] = await Promise.all([
            callService.options.call(1),
            callService.finished.call(),
            callService.result.call(),
            dao.votingPrice()
        ]);


        assert.deepEqual(option1, result, "Result is invalid");
        assert.isTrue(isFinished, "Call service was not finished");
        assert.deepEqual(votingPriceBefore.times(multiplier), votingPriceAfter);
    });

    it("Should finish callService and call method with price", async () => {
        const [backersToWei, backersToOption] = getBakers();

        const service = await ExampleService.new(1, 1, DXC.address, ProxyAPI.address);
        await helper.payForVoting(dao, accounts[0]);
        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true, service.address);
        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, false, true, service.address);
        const votingPriceBefore = await dao.votingPrice();
        const initialCapitalBefore = await dao.initialCapital();
        await callService.finish.sendTransaction();

        const [option1, isFinished, result, votingPriceAfter, initialCapitalAfter] = await Promise.all([
            callService.options.call(1),
            callService.finished.call(),
            callService.result.call(),
            dao.votingPrice(),
            dao.initialCapital()
        ]);


        assert.deepEqual(option1, result, "Result is invalid");
        assert.isTrue(isFinished, "Call service was not finished");
        assert.deepEqual(votingPriceBefore.times(multiplier), votingPriceAfter);
        assert.deepEqual(web3.toBigNumber('0'), await service.callDeposit(dao.address));
        assert.deepEqual(initialCapitalBefore.minus(await service.priceToCall()), initialCapitalAfter);
    });

    it("Should create proposal if initial capital is not enough", async () => {
        const [backersToWei, backersToOption] = getBakers();

        const service = await ExampleService.new(1, web3.toWei(2), DXC.address, ProxyAPI.address);
        await helper.payForVoting(dao, accounts[0]);
        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true, service.address);
        return helper.handleErrorTransaction(() => makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, false, true, service.address));
    });

    it("Should not call method in service after finish if initial capital is not enough", async () => {
        const [backersToWei, backersToOption] = getBakers();

        const service = await ExampleService.new(web3.toWei('0.9'), web3.toWei('0.11'), DXC.address, ProxyAPI.address);
        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true, service.address);
        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, false, true, service.address);
        const service2 = await ExampleService.new(web3.toWei('0.4'), 1, DXC.address, ProxyAPI.address);
        await makeDAOAndCreateNewService(backersToWei, backersToOption, backer1, true, true, service2.address);

        return helper.handleErrorTransaction(() => callService.finish.sendTransaction());
    });

    it("Should not finish callService when time is not up", async () => {
        const [backersToWei, backersToOption] = getBakers();

        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, false, false);

        return helper.handleErrorTransaction(() => callService.finish.sendTransaction());
    });

    it("Should not add vote when time is up", async () => {
        const [backersToWei, backersToOption] = getBakers();

        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1,  false, true);

        return helper.handleErrorTransaction(() => callService.addVote.sendTransaction(1, {from: backer2}));
    });

    it("Should not finish callService twice", async () => {
        const [backersToWei, backersToOption] = getBakers();

        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, true, true);

        return helper.handleErrorTransaction(() => callService.finish.sendTransaction());
    });

    it("Team member can't add vote", async () => {
        const backers = [backer1, backer2, teamPerson1, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        backersToOption[`${backers[0]}`] = 1;
        backersToOption[`${backers[1]}`] = 2;
        backersToOption[`${backers[2]}`] = 1;
        backersToOption[`${backers[3]}`] = 1;

        return helper.handleErrorTransaction(() => makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, false, false));
    });

    it("Should not accept callService when amount of votes for option#1 equals amount of votes for option#2", async () => {
        const backers = [backer1, backer2, backer3, backer4];
        const [backersToWei, backersToOption] = [{}, {}];
        for (let i = 0; i < backers.length; i++) {
            backersToWei[`${backers[i]}`] = web3.toWei(5, "ether");
            backersToOption[`${backers[i]}`] = i % 2 === 0 ? 1 : 2; // 10 eth (in tokens) for "yes" and 10 eth (in tokens) for "no"
        }

        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1,  true, true);

        const [option1, option2, isFinished, result] = await Promise.all([
            callService.options.call(1),
            callService.options.call(2),
            callService.finished.call(),
            callService.result.call()
        ]);

        assert.deepEqual(option1[0], option2[0]);
        assert.isTrue(isFinished);
        assert.deepEqual(option2, result);
    });

    it("Should accept callService when 80% votes for option#1", async () => {
        const [backersToWei, backersToOption] = getBakers([8,8,2,2], [1,1,2,2]);

        await makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, true, true);

        const token = Token.at(await dao.token.call());

        const [totalSupply, teamTokensAmount, option1, result, isFinished] = await Promise.all([
            token.totalSupply.call(),
            dao.teamTokensAmount.call(),
            callService.options.call(1),
            callService.result.call(),
            callService.finished.call(),
        ]);

        const teamTokensPercentage = teamBonuses.reduce((pv, ct) => pv + ct, 0);

        assert.deepEqual(option1, result, "New Service should be accepted");
        assert.equal((totalSupply.toNumber() - teamTokensAmount.toNumber()) / 100 * teamTokensPercentage, teamTokensAmount.toNumber(), "Team percentage was not calculated correct");
        assert.isTrue(isFinished, "New Service was not finished");
    });

    it("Should not create callService voting if initial capital is less than service price", async () => {
        const [backersToWei, backersToOption] = getBakers([8,8,2,2], [1,1,2,2]);

        const service = await ExampleService.new(1, 1, DXC.address, ProxyAPI.address);
        await helper.payForVoting(dao, accounts[0]);
        return helper.handleErrorTransaction(() => makeDAOAndCreateCallService(backersToWei, backersToOption, backer1, true, true, service.address));
    });

    it("Should not let create proposal if not enough DXC for voting price was transferred", async () => {
        const dxc = await helper.mintDXC(accounts[0], web3.toWei('0.09'));
        await dxc.contributeTo.sendTransaction(dao.address, web3.toWei('0.09'));

        return helper.handleErrorTransaction(() => createCallService(accounts[0], ExampleService.address));
    });

    it("Should not let create proposal if not enough DXC for voting price was transferred", async () => {
        await helper.payForVoting(dao, accounts[3]);

        return helper.handleErrorTransaction(() => createCallService(accounts[3], ExampleService.address));
    });
});