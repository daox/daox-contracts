"use strict";
const DAOx = artifacts.require("./DAOx.sol");

contract("DAOx", accounts => {
    const serviceAccount = accounts[0];
    const unknownUser = accounts[1];

    it("Unknown user should not be in Users", () =>
        DAOx.deployed()
            .then(instance => instance.setDaoFactory.send("0x0", unknownUser))
            .then(doesExist => assert.equal(false, doesExist, "Unknown user exists in User contract"))
    );


});