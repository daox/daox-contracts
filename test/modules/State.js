"use strict";
const helper = require('../helpers/helper.js');

contract("State", accounts => {
    const serviceAccount = accounts[0];
    const uknownAccount = accounts[1];
    const [daoName, daoDescription, tokenName, tokenSymbol] = ["DAO NAME", "THIS IS A DESCRIPTION", "TEST TOKEN", "TTK"];

    let cdf, dao = [null, null];

    before(async () => cdf = await helper.createCrowdsaleDAOFactory(accounts));
    beforeEach(async () => dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription]));

    it("Should create DAO with correct parameters", async () => {
        const result = await cdf.exists.call(dao.address);

        assert.equal(true, result, "Created crowdsale DAO should exist");
        assert.equal(daoName, await dao.name.call(), "DAO's name doesn't correspond to the expected");
        assert.equal(helper.fillZeros(web3.toHex(daoDescription)), await dao.description.call(), "DAO's description doesn't correspond to the expected");
    });

    it("Should correct init state from service account", async () => {
        const [daoxAddress, votingFactoryAddress, token] = await helper.getParametersForInitState(cdf, tokenName, tokenSymbol);

        await dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, {
            from: serviceAccount
        });

        assert.equal(daoxAddress, await dao.serviceContract.call());
        assert.equal(votingFactoryAddress, await dao.votingFactory.call());
        assert.equal(token.address, await dao.token.call());
        assert.equal(false, await dao.canInitStateParameters.call(), "`canInitState` variable was not changed");
        assert.isDefined(await dao.commissionContract.call(), "Commission contract was not created");
    });

    it("Should not correct init state from unknown account", async () => {
        const [daoxAddress, votingFactoryAddress, token] = await helper.getParametersForInitState(cdf, tokenName, tokenSymbol);

        return await helper.handleErrorTransaction(() => dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, {
            from: uknownAccount
        }));
    });

    it("Should not init state twice", async () => {
        const [daoxAddress, votingFactoryAddress, token] = await helper.getParametersForInitState(cdf, tokenName, tokenSymbol);

        await dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, {
            from: serviceAccount
        });

        return await helper.handleErrorTransaction(() => dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, {
            from: serviceAccount
        }));
    });

    it("Should not init state when crowdsale started", async () => {
        const [daoxAddress, votingFactoryAddress, token] = await helper.getParametersForInitState(cdf, tokenName, tokenSymbol);

        const latestBlock = await helper.getLatestBlock(web3);

        await dao.initCrowdsaleParameters.sendTransaction(1, 3, 5, latestBlock.timestamp + 100, latestBlock.timestamp * 2, {
            from: serviceAccount
        });

        await helper.rpcCall(web3, "evm_increaseTime", [100], 0);

        return helper.handleErrorTransaction(() => dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, {
            from: serviceAccount
        }));
    });
});