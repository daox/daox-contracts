"use strict";
const helper = require('./helpers/helper.js');

contract("CrowdsaleDAOFactory", accounts => {
    let cdf;
    before(async () => cdf = await helper.createCrowdsaleDAOFactory());

    it("Unknown dao should not be in Factory", async () => {
        const result = await cdf.exists.call(accounts[0]);

        assert.equal(false, result, "Unknown DAO exists in User contract");
    });

    it("Should not create DAO without dxc deposit", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];

        return helper.handleErrorTransaction(() => cdf.createCrowdsaleDAO(daoName, daoDescription, web3.toWei('1')));
    });

    it("Should not let to transfer less than 1 DXC to CrowdsaleDAOFactory", async () => {
        const dxc = await helper.mintDXC(accounts[0], web3.toWei('1'));
        return helper.handleErrorTransaction(() => dxc.contributeTo.sendTransaction(cdf.address, web3.toWei('0.5')));
    });

    it("Should increase dxc deposit only when called by DXC contract", async () =>
        helper.handleErrorTransaction(() => cdf.handleDXCPayment.sendTransaction(accounts[1], web3.toWei('1'), {from: accounts[1]})));

    it("Should not create DAO with dxc deposit made by another user", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
        const dxc = await helper.mintDXC(accounts[1], web3.toWei('1'));
        await dxc.contributeTo.sendTransaction(cdf.address, web3.toWei('1'), {from: accounts[1]});

        return helper.handleErrorTransaction(() => cdf.createCrowdsaleDAO(daoName, daoDescription, web3.toWei('1')));
    });

    it("Should not create DAO with dxc deposit less than 1 DXC", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
        const dxc = await helper.mintDXC(accounts[0], web3.toWei('1'));
        await dxc.contributeTo.sendTransaction(cdf.address, web3.toWei('1'));

        return helper.handleErrorTransaction(() => cdf.createCrowdsaleDAO(daoName, daoDescription, web3.toWei('0.5')));
    });

    it("Should create DAO with initial capital less than 20 DXC", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
        const dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription]);
        const result = await cdf.exists.call(dao.address);

        assert.equal(true, result, "Created crowdsale DAO should exist");
        assert.equal(daoName, await dao.name());
        assert.equal(daoDescription, await dao.description());
        assert.equal(web3.toWei('1'), (await dao.initialCapital()).toNumber());
        assert.equal(web3.toWei('0.1'), (await dao.votingPrice()).toNumber());
    });

    it("Should create DAO with initial capital more or equal to 20 DXC", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
        const dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription], '20');
        const result = await cdf.exists.call(dao.address);

        assert.equal(true, result, "Created crowdsale DAO should exist");
        assert.equal(daoName, await dao.name());
        assert.equal(daoDescription, await dao.description());
        assert.equal(web3.toWei('20'), (await dao.initialCapital()).toNumber());
        assert.equal(web3.toWei('2'), (await dao.votingPrice()).toNumber());
    });
});