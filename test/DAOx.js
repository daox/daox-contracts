"use strict";
const DAOx = artifacts.require("./DAOx.sol");
let daox;

contract("DAOx", accounts => {
    const serviceAccount = accounts[0];
    const unknownUser = accounts[1];
    beforeEach(() => DAOx.new().then(_daox => daox = _daox));

    it("DaoFactory can't be set by not owner", () =>
        daox.setDaoFactory("0x1", unknownUser, {from: unknownUser}).catch(e => assert.isDefined(e)));

    it("DaoFactory can be set by owner", () =>
        daox.setDaoFactory("0x1", serviceAccount, {from: unknownUser}).catch(e => assert.isUndefined(e)));

    it("DaoFactory address can't be empty", () =>
        daox.setDaoFactory("0x0", serviceAccount, {from: unknownUser}).catch(e => assert.isDefined(e)));

    it("DaoFactory can't be set twice", () =>
        daox.setDaoFactory("0x1", serviceAccount, {from: unknownUser})
            .then(() => daox.setDaoFactory("0x1", serviceAccount, {from: unknownUser}))
            .catch(e => assert.isDefined(e)));
});