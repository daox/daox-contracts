"use strict";
const Users = artifacts.require("./Users/Users.sol");


contract("Users", accounts => {
    let users = null;

    beforeEach(() => Users.new().then(_users => users = _users));
    const serviceAccount = accounts[0];
    const unknownUser = accounts[1];
    const userName = "Name";
    const userSecondName = "SecondName";
    const userEmail = "Email";

    it("Unknown user should not be in Users", () =>
        users.doesExist.call(unknownUser)
            .then(doesExist => assert.equal(false, doesExist, "Unknown user exists in User contract")));

    it("Should register new user and set correct data", () =>
        users.registerNewUser(userName, userSecondName, userEmail, unknownUser, {from: serviceAccount})
            .then(() => users.doesExist.call(unknownUser))
            .then(doesExist => {
                assert.equal(true, doesExist, "User should exist after registering");

                return users.users.call(unknownUser);
            })
            .then(user => {
                assert.equal(web3.sha3(userName), user[0], "UserName was not saved correctly");
                assert.equal(web3.sha3(userSecondName), user[1], "SecondName was not saved correctly");
                assert.equal(web3.sha3(userEmail), user[2], "UserEmail was not saved correctly");
            }));
});