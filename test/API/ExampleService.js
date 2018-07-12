"use strict";
const ExampleService = artifacts.require("./DAO/API/ExampleService.sol");
let TypesConverter = artifacts.require("./DAO/API/TypesConverter.sol");
const helper = require('../helpers/helper.js');

contract("ExampleService", accounts => {
    // TypesConverter = TypesConverter.at(TypesConverter.address);
    // let cdf, dao;
    //
    // before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    // beforeEach(async () => dao = await helper.createCrowdsaleDAO(cdf, accounts));
    //
    // it("Should change voting price via api call", async () => {
    //     const multiplier = 15;
    //     const previousVotingPrice = await dao.votingPrice();
    //     const bytes32Multiplier = await TypesConverter.uintToBytes32(multiplier);
    //     await dao.callService.sendTransaction(ExampleService.address, web3.toHex("changeVotingPrice"),
    //         [bytes32Multiplier, web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null)]);
    //     const newVotingPrice = await dao.votingPrice();
    //     assert.deepEqual(previousVotingPrice.times(multiplier), newVotingPrice);
    // });
    //
    // it("`handleAPICall` can not be called from not proxy api contract", async () =>
    //     helper.handleErrorTransaction(async () => dao.handleAPICall("setVotingPrice(bytes32)", await TypesConverter.uintToBytes32(15))));
});