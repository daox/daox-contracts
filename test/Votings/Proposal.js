"use strict";
const helper = require('../helpers/helper.js');
const Proposal = artifacts.require('./Votings/Proposal.sol');
const CrowdsaleDAO = artifacts.require('./DAO/CrowdsaleDAO.sol');
const Token = artifacts.require('./Token/Token.sol');


contract("Proposal", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];

    let proposal, dao;
    before(async () => {
        const cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf);
        await dao.setWhiteList.sendTransaction([serviceAccount]);
        await helper.makeCrowdsale(web3, cdf, dao, accounts);
    });

    beforeEach(async () => {
        const tx = await dao.addProposal('Test description', 100, ['yes', 'no', 'maybe']);
        const logs = helper.decodeVotingParameters(tx);
        proposal = Proposal.at(logs[0]);
    });

    it("Should add vote from 2 different accounts", async () => {

        const [, , latestBlock] = await Promise.all([
            proposal.addVote(1),
            proposal.addVote(3, {from: unknownAccount}),
            helper.getLatestBlock(web3)
        ]);

        const token = Token.at(await dao.token.call());

        const [option1, option2, balance1, balance2] = await Promise.all([
            proposal.options.call(1),
            proposal.options.call(3),
            await token.balanceOf.call(serviceAccount),
            await token.balanceOf.call(unknownAccount),
        ]);

        assert.equal(balance1.toNumber(), option1[0].toNumber());
        assert.equal(balance2.toNumber(), option2[0].toNumber());
        assert.equal(1, await proposal.voted.call(serviceAccount));
        assert.equal(3, await proposal.voted.call(unknownAccount));
        assert.equal(
            Math.round(web3.fromWei(balance1.toNumber() + balance2.toNumber())),
            Math.round(web3.fromWei((await proposal.votesCount.call())))
        );
        assert.equal(latestBlock.timestamp + 100, (await token.held.call(serviceAccount)).toNumber());
        assert.equal(latestBlock.timestamp + 100, (await token.held.call(unknownAccount)).toNumber());
    });

    it("Should finish voting", async () => {
        let callID = 0;

        await Promise.all([
            await proposal.addVote(1),
            await proposal.addVote(3, {from: unknownAccount}),
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [110], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);
        await proposal.finish();

        assert.equal(true, await proposal.finished.call());
        assert.deepEqual(await proposal.result.call(), await proposal.options.call(1));
    });
});