"use strict";
const Users = artifacts.require("./Users/Users.sol");
let users = null;


contract("Users", accounts => {
    beforeEach(() => Users.new().then(_users => users = _users));
    const serviceAccount = accounts[0];
    const unknownUser = accounts[1];

    it("Unknown user should not be in Users", () =>
        users.doesExist.call(unknownUser).then(doesExist => assert.equal(false, doesExist, "Unknown user exists in User contract")));

    it("Should register new user", () =>
        users.registerNewUser("UserName", "UserSecondName", "UserEmail", unknownUser, {from: serviceAccount})
            .then(() => users.doesExist.call(unknownUser))
            .then(doesExist => assert.equal(true, doesExist, "User should exist after registering")));
});