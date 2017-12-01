"use strict";
const helper = require('./helpers/helper.js');
let cdf;

contract("VotingFactory", accounts => {
    const serviceAccount = accounts[0];
    const unknownUser = accounts[1];
    beforeEach(() => helper.createCrowdasaleDAOFactory(accounts).then(_cdf => cdf = _cdf));

    it("DaoFactory address can't be empty", () =>
        cdf.votingFactory.setDaoFactory("0x0", serviceAccount, {from: unknownUser}).catch(e => assert.isDefined(e)));

    it("DaoFactory can't be set twice", () =>
        cdf.votingFactory.setDaoFactory("0x1", serviceAccount, {from: unknownUser})
            .then(() => vf.setDaoFactory("0x1", serviceAccount, {from: unknownUser}))
            .catch(e => assert.isDefined(e)));

    it("Should create proposal", () =>
        cdf.votingFactory.createProposal(serviceAccount, "test description", 1, ["","","","","","","","","",""], {from: serviceAccount})
            .then(proposal => assert.isString(proposal)));
});