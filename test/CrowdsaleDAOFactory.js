"use strict";
const helper = require('./helpers/helper.js');

contract("CrowdsaleDAOFactory", accounts => {
    let cdf;
    beforeEach(() => helper.createCrowdasaleDAOFactory(accounts).then(_cdf => cdf = _cdf));

    it("Unknown dao should not be in Factory", () => {
        return cdf.exists.call(accounts[0])
            .then(doesExist => assert.equal(false, doesExist, "Unknown DAO exists in User contract"))
        // .catch(err => assert.isDefined(err))
    });
});