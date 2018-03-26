"use strict";
const helper = require('../helpers/helper.js');
const DXC = artifacts.require("./Token/DXC.sol");

contract("State", accounts => {
    const serviceAccount = accounts[0];
    const unknownAccount = accounts[1];
    const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];

    let cdf, dao = [null, null];

    before(async () => cdf = await helper.createCrowdsaleDAOFactory(accounts));
    beforeEach(async () => dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription]));

    it("Should create DAO with correct parameters", async () => {
        const result = await cdf.exists.call(dao.address);

        assert.equal(true, result, "Created crowdsale DAO should exist");
        assert.equal(daoName, await dao.name.call(), "DAO's name doesn't correspond to the expected");
        assert.equal(daoDescription, await dao.description.call(), "DAO's description doesn't correspond to the expected");
    });

    it("Should correct init state from service account", async () => {
        const [daoxAddress, votingFactoryAddress, token] = await helper.initState(cdf, dao, serviceAccount);

        assert.equal(daoxAddress, await dao.serviceContract.call());
        assert.equal(votingFactoryAddress, await dao.votingFactory.call());
        assert.equal(token.address, await dao.token.call());
        assert.equal(DXC.address, await dao.DXC.call());
        assert.equal(false, await dao.canInitStateParameters.call(), "`canInitState` variable was not changed");
        assert.isDefined(await dao.commissionContract.call(), "Commission contract was not created");
    });

    it("Should not correct init state from unknown account", async () =>
        helper.handleErrorTransaction(() => helper.initState(cdf, dao, unknownAccount)));

    it("Should not init state twice", async () => {
        await helper.initState(cdf, dao, serviceAccount);

        return await helper.handleErrorTransaction(() => helper.initState(cdf, dao, serviceAccount));
    });

    it("Should not init state when crowdsale started", async () => {
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);

        await helper.rpcCall(web3, "evm_increaseTime", [100]);

        return helper.handleErrorTransaction(() => helper.initState(cdf, dao, serviceAccount));
    });
});