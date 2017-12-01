"use strict";
const helper = require('./helpers/helper.js');
const Web3 = require("web3");
const web3 = new Web3();

contract("CrowdsaleDAOFactory", accounts => {
    const [daoName, daoDescription, daoMinVote, DAOOwner, softCap, hardCap, rate, startBlock, endBlock] = ["Test", "Test DAO", 51, accounts[2], 100, 1000, 100, 100, 100000];
    const serviceAccount = accounts[0];

    let cdf;
    beforeEach(() => helper.createCrowdasaleDAOFactory(accounts).then(_cdf => cdf = _cdf));

    it("Unknown dao should not be in Factory", () =>
        cdf.exists.call(accounts[0])
            .then(doesExist => assert.equal(false, doesExist, "Unknown DAO exists in User contract")));

    it("Should create DAO", () =>
        cdf.createCrowdsaleDAO(daoName, daoDescription, daoMinVote, DAOOwner, cdf.token.address, softCap, hardCap, rate, startBlock, endBlock)
            .then(tx => {
                const result = web3.eth.abi.decodeParameters(["address", "string"], tx.receipt.logs[0].data);

                return cdf.exists.call(result[0]);
            })
            .then(doesExist => assert.equal(true, doesExist, "Created crowdsale DAO should exist")));
});