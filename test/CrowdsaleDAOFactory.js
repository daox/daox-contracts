"use strict";
const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");
const Users = artifacts.require("./Users/Users.sol");

contract("Users", accounts => {
    it("test", () =>
        Users.deployed()
            .then(instance => instance.doesExist.call(accounts[0]))
            .then(result => assert.equal(false, result))
    );
});