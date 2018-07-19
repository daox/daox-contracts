"use strict";
const helper = require('./helpers/helper.js');
const ExampleService = artifacts.require('./DAO/API/ExampleService.sol');
let TypesConverter = artifacts.require("./DAO/API/TypesConverter.sol");
TypesConverter = TypesConverter.at(TypesConverter.address);

contract("CrowdsaleDAO", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];

    let cdf, dao;

    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => dao = await helper.createCrowdsaleDAO(cdf, accounts));

    it("Should initiate bonus periods and token bonuses for team", async () => {
        const [date,] = await helper.initBonuses(dao, accounts, web3);

        assert.equal(serviceAccount, await dao.team.call(0));
        assert.equal(5, await dao.teamBonusesArr.call(0));
        assert.equal(5, await dao.teamBonuses.call(serviceAccount));
        assert.equal(unknownAccount, await dao.team.call(1));
        assert.equal(10, await dao.teamBonusesArr.call(1));
        assert.equal(10, await dao.teamBonuses.call(unknownAccount));

        assert.equal(date, (await dao.bonusPeriods.call(0)).toNumber());
        assert.equal(date + 60, (await dao.bonusPeriods.call(1)).toNumber());

        assert.equal(10, (await dao.bonusEtherRates.call(0)).toNumber());
        assert.equal(20, (await dao.bonusEtherRates.call(1)).toNumber());
        assert.equal(100, (await dao.bonusDXCRates.call(0)).toNumber());
        assert.equal(200, (await dao.bonusDXCRates.call(1)).toNumber());
        assert.equal(false, await dao.canInitBonuses.call());
    });

    it("Should not initiate bonuses when periods and rates count mismatch", async () => {
        const block = await helper.getLatestBlock(web3);
        const date = block.timestamp;
        const holdTime = 60 * 60 * 24;

        return helper.handleErrorTransaction(() => dao.initBonuses([serviceAccount, unknownAccount], [5, 10], [date], [10, 20], [100, 200], [holdTime, holdTime]))
    });

    it("Should not initiate bonuses when periods and dxc rates count mismatch", async () => {
        const block = await helper.getLatestBlock(web3);
        const date = block.timestamp;
        const holdTime = 60 * 60 * 24;

        return helper.handleErrorTransaction(() => dao.initBonuses([serviceAccount, unknownAccount], [5, 10], [date, date + 60], [10, 20], [100, 200, 300], [holdTime, holdTime]))
    });

    it("Should initiate bonuses when dxc rates length = 0", async () => {
        const block = await helper.getLatestBlock(web3);
        const date = block.timestamp;
        const holdTime = 60 * 60 * 24;

        await dao.initBonuses([serviceAccount, unknownAccount], [5, 10], [date, date + 60], [10, 20], [], [holdTime, holdTime], [false, false]);
    });

    it("Should not initiate bonuses when team members and team bonuses count mismatch", async () => {
        const block = await helper.getLatestBlock(web3);
        const date = block.timestamp;
        const holdTime = 60 * 60 * 24;

        return helper.handleErrorTransaction(() => dao.initBonuses([serviceAccount, unknownAccount], [5], [date, date + 60], [10, 20], [100, 200], [holdTime, holdTime]))
    });

    it("Should not initiate bonuses when team members and team hold count mismatch", async () => {
        const block = await helper.getLatestBlock(web3);
        const date = block.timestamp;
        const holdTime = 60 * 60 * 24;

        return helper.handleErrorTransaction(() => dao.initBonuses([serviceAccount, unknownAccount], [5, 10], [date, date + 60], [10, 20], [100, 200], [holdTime]))
    });

    it("Should not be able to initiate bonus periods and token bonuses for team twice", async () => {
        await helper.initBonuses(dao, accounts, web3);

        return helper.handleErrorTransaction(() => helper.initBonuses(dao, accounts, web3));
    });

    it("Should not be able to initiate bonus periods and token bonuses for team after start of crowdsale", async () => {
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);

        return helper.handleErrorTransaction(() => helper.initBonuses(dao, accounts, web3));
    });

    it("Should not be able to initiate bonus periods and token bonuses for team from not owner", async () => {
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);

        return helper.handleErrorTransaction(() => helper.initBonuses(dao, [unknownAccount, serviceAccount], web3));
    });

    it("Should set white list addresses", async () => {
        await dao.setWhiteList.sendTransaction([serviceAccount, unknownAccount]);

        assert.equal(serviceAccount, await dao.whiteListArr.call(0));
        assert.equal(true, await dao.whiteList.call(serviceAccount));
        assert.equal(unknownAccount, await dao.whiteListArr.call(1));
        assert.equal(true, await dao.whiteList.call(unknownAccount));
        assert.equal(false, await dao.canSetWhiteList.call());
    });

    it("Should not be able to set white list addresses twice", async () => {
        await dao.setWhiteList.sendTransaction([serviceAccount, unknownAccount]);

        return helper.handleErrorTransaction(() => dao.setWhiteList([serviceAccount, unknownAccount]));
    });

    it("Should not be able to set white list addresses from not owner", () =>
        helper.handleErrorTransaction(
            () => dao.setWhiteList.sendTransaction([serviceAccount, unknownAccount], {from: unknownAccount})));

    it("Should not be able to set voting factory address from not voting", () =>
        helper.handleErrorTransaction(
            () => dao.setVotingFactoryAddress.sendTransaction("0x1", {from: unknownAccount})));

    it("Should not be able to set service voting factory address from not voting", () =>
        helper.handleErrorTransaction(
            () => dao.setServiceVotingFactory.sendTransaction("0x1", {from: unknownAccount})));

    it("Should not be able to connect service before setting crowdsale params", async () => {
        const initialCapitalBefore = await dao.initialCapital();
        await dao.connectService(ExampleService.address);
        const service = ExampleService.at(ExampleService.address);

        assert.isTrue(await dao.services(ExampleService.address));
        assert.isTrue(await service.daos(dao.address));
        assert.deepEqual(initialCapitalBefore, (await dao.initialCapital()).plus(await service.priceToConnect()));
    });

    it("Should not be able to call method from service which requires voting", async () => {
        await dao.connectService(ExampleService.address);
        const bytes32Multiplier = await TypesConverter.uintToBytes32(2);
        const args = [bytes32Multiplier, web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null)];

        return helper.handleErrorTransaction(
            () => dao.callService.sendTransaction(ExampleService.address, web3.toHex("changeVotingPrice"), args));
    });

    it("Should be able to call method from service which doesn't require voting", async () => {
        await dao.connectService(ExampleService.address);
        const args = [web3.toHex("Call Service Name"), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null)];

        await dao.callService.sendTransaction(ExampleService.address, web3.toHex("changeName"), args);

        assert.equal("Call Service Name", await dao.name());
    });


});