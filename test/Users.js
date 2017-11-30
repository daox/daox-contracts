"use strict";
const Users = artifacts.require("./Users/Users.sol");

contract("Users", accounts => {
    const serviceAccount = accounts[0];
    const unknownUser = accounts[1];

    it("Unknown user should not be in Users", () =>
        Users.deployed()
            .then(instance => instance.doesExist.call(unknownUser))
            .then(doesExist => assert.equal(false, doesExist, "Unknown user exists in User contract"))
    );

    it("Should register new user", () => {
        let UserInstance;

        return Users.deployed().then(instance => {
            UserInstance = instance;

            return UserInstance.registerNewUser("UserName", "UserSecondName", "UserEmail", unknownUser, {from : serviceAccount});
        })
            .then(() => UserInstance.doesExist.call(unknownUser))
            .then(doesExist => assert.equal(true, doesExist, "User should exist after registering"));
    });


});