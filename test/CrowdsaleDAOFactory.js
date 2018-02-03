"use strict";
const helper = require('./helpers/helper.js');

contract("CrowdsaleDAOFactory", accounts => {
    let cdf;
    before(async () => cdf = await helper.createCrowdsaleDAOFactory());

    it("Unknown dao should not be in Factory", async () => {
        const result = await cdf.exists.call(accounts[0]);

        assert.equal(false, result, "Unknown DAO exists in User contract");
    });

    it("Should create DAO", async () => {
        const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
        const dao = await helper.createCrowdsaleDAO(cdf, [daoName, daoDescription]);
        const result = await cdf.exists.call(dao.address);

        assert.equal(true, result, "Created crowdsale DAO should exist");
    });
});