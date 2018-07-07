"use strict";
const ExampleModule = artifacts.require("./DAO/API/ExampleModule.sol");
let TypesConverter = artifacts.require("./DAO/API/TypesConverter.sol");
const helper = require('../helpers/helper.js');

contract("CrowdsaleDAO", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];

    let cdf, dao;

    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => dao = await helper.createCrowdsaleDAO(cdf, accounts));

    it("Should change voting price via api call", async () => {
        const multiplier = 15;
        const previousVotingPrice = await dao.votingPrice();
        TypesConverter = TypesConverter.at(TypesConverter.address);
        const bytes32Multiplier = await TypesConverter.uintToBytes32(multiplier);
        await dao.callService.sendTransaction(ExampleModule.address, web3.toHex("changeVotingPrice"),
            [bytes32Multiplier, web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null), web3.toHex(null)]);
        const newVotingPrice = await dao.votingPrice();
        assert.deepEqual(previousVotingPrice.times(multiplier), newVotingPrice);
    });
});