"use strict";
const helper = require('./helpers/helper.js');
const Module = artifacts.require('./Votings/Service/Module.sol');
const NewService = artifacts.require('./Votings/Service/NewService.sol');
const ServiceVotingFactory = artifacts.require('./Votings/Service/ServiceVotingFactory.sol');
const ExampleService = artifacts.require('./DAO/API/ExampleService.sol');

contract("ServiceVotingFactory", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    const minimalDurationPeriod = 60 * 60 * 24 * 7;
    const name = "Voting name";

    let cdf, dao;
    before(async () => {
        cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf, accounts);
        await dao.setWhiteList.sendTransaction([serviceAccount]);
        await helper.initBonuses(dao, accounts, web3, true);
        await helper.makeCrowdsale(web3, cdf, dao, accounts);
    });

    it("Should create module", async () => {
        const description = 'Test Description';
        await helper.payForVoting(dao, serviceAccount);
        const tx = await dao.addModule(name, description, minimalDurationPeriod, 1, unknownAccount);
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const [option1, option2] = await Promise.all([
            module.options.call(1),
            module.options.call(2),
        ]);

        assert.equal(description, await module.description.call());
        assert.equal(helper.fillZeros(web3.toHex('yes')), option1[1]);
        assert.equal(helper.fillZeros(web3.toHex('no')), option2[1]);
        assert.equal(minimalDurationPeriod, await module.duration.call());
        assert.equal(1, await module.module.call());
        assert.equal(unknownAccount, await module.newModuleAddress.call());
        assert.equal(false, await module.finished.call());
    });

    it("Should create newService", async () => {
        const description = 'Test Description';
        await helper.payForVoting(dao, serviceAccount);
        const tx = await dao.addNewService(name, description, minimalDurationPeriod, ExampleService.address);
        const logs = helper.decodeVotingParameters(tx);
        const newService = NewService.at(logs[0]);

        const [option1, option2] = await Promise.all([
            newService.options.call(1),
            newService.options.call(2),
        ]);

        assert.equal(description, await newService.description.call());
        assert.equal(helper.fillZeros(web3.toHex('yes')), option1[1]);
        assert.equal(helper.fillZeros(web3.toHex('no')), option2[1]);
        assert.equal(minimalDurationPeriod, await newService.duration.call());
        assert.equal(ExampleService.address, await newService.service.call());
        assert.equal(false, await newService.finished.call());
    });

    it("Should not be able to create any voting from not participant", async () => {
        const description = 'Test Description';

        return Promise.all([
            helper.handleErrorTransaction(() => dao.addModule(name, description, minimalDurationPeriod, 1, unknownAccount, {from: accounts[2]})),
            helper.handleErrorTransaction(() => dao.addNewService(name, description, minimalDurationPeriod, ExampleService.address)),
        ]);
    });

    it("Should not be able to create any voting from not dao", async () => {
        const description = 'Test Description';
        const serviceVotingFactory = ServiceVotingFactory.at(await dao.serviceVotingFactory.call());

        return Promise.all([
            helper.handleErrorTransaction(() => serviceVotingFactory.addModule(serviceAccount, name, description, minimalDurationPeriod, 1, unknownAccount)),
            helper.handleErrorTransaction(() => serviceVotingFactory.addNewService(name, description, minimalDurationPeriod, ExampleService.address))
        ]);
    });

    it("Should not be able to create any voting before succeeded crowdsale", async () => {
        const description = 'Test Description';

        const daoTest = await helper.createCrowdsaleDAO(cdf, accounts);
        await daoTest.setWhiteList.sendTransaction([serviceAccount]);
        await helper.makeCrowdsale(web3, cdf, daoTest, accounts, false);
        await helper.payForVoting(dao, serviceAccount);

        return Promise.all([
            helper.handleErrorTransaction(() => daoTest.addModule(name, description, minimalDurationPeriod, 1, unknownAccount)),
            helper.handleErrorTransaction(() => daoTest.addNewService(name, description, minimalDurationPeriod, ExampleService.address))
        ]);
    });
});