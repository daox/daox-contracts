"use strict";
const helper = require('./helpers/helper.js');

contract("CrowdsaleDAOFactory", accounts => {
    const [daoName, daoDescription, daoMinVote, DAOOwner, softCap, hardCap, rate, startBlock, endBlock] = ["Test", "Test DAO", 51, accounts[2], 100, 1000, 100, 100, 100000];
    const serviceAccount = accounts[0];

    let cdf;
    beforeEach(() => helper.createCrowdsaleDAOFactory(accounts).then(_cdf => cdf = _cdf));

    it("Test", async () => {
        console.log(cdf);
    });

    // it("Unknown dao should not be in Factory", () =>
    //     cdf.exists.call(accounts[0])
    //         .then(doesExist => assert.equal(false, doesExist, "Unknown DAO exists in User contract")));

    // it("Should create DAO", () =>
    //     helper.createCrowdsaleDAO(cdf, accounts).then(createCrowdasaleDAOcdf => cdf.exists.call(cdf.dao._address))
    //         .then(doesExist => assert.equal(true, doesExist, "Created crowdsale DAO should exist")));

});