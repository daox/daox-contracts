"use strict";
const helper = require('./helpers/helper.js');

contract("CrowdsaleDAOFactory", accounts => {
    const [daoName, daoDescription, daoMinVote, DAOOwner, softCap, hardCap, rate, startBlock, endBlock] = ["Test", "Test DAO", 51, accounts[2], 100, 1000, 100, 100, 100000];
    const serviceAccount = accounts[0];

    let cdf;
    beforeEach(async () => cdf = await helper.createCrowdsaleDAOFactory(accounts));

    it("Unknown dao should not be in Factory", async () => {
        const result = await cdf.exists.call(accounts[0]);

        assert.equal(false, result, "Unknown DAO exists in User contract");
    });

    it("Should create DAO with correct fields", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
        const dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription]);
        const result = await cdf.exists.call(dao.address);

        assert.equal(true, result, "Created crowdsale DAO should exist");
        assert.equal(daoName, await dao.name.call(), "DAO's name doesn't correspond to the expected");
        assert.equal(helper.fillZeros(web3.toHex(daoDescription)), await dao.description.call(), "DAO's description doesn't correspond to the expected");
    });

    it("Should set correct parameters in initState", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
        const dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription]);
        const [daoxAddress, votingFactoryAddress, token] = await Promise.all([cdf.serviceContractAddress.call(), cdf.votingFactoryContractAddress.call(), helper.createToken("ANTOKEN", "ANT")]);

        const tx = await dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, {
            from : serviceAccount
        });

        assert.equal(daoxAddress, await dao.serviceContract.call());
        assert.equal(votingFactoryAddress, await dao.votingFactory.call());
        assert.equal(token.address, await dao.token.call());
    })

});