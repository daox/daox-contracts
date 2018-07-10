"use strict";
const helper = require('../helpers/helper.js');
const Regular = artifacts.require('./Votings/Common/Regular.sol');
const Token = artifacts.require('./Token/Token.sol');

contract("Regular", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];
    let duration = 60 * 60 * 24 * 7;
    const name = "Voting name";

    let regular, dao, token;
    before(async () => {
        const cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf, accounts);
        await dao.setWhiteList.sendTransaction([serviceAccount]);
        await helper.makeCrowdsale(web3, cdf, dao, accounts);

        token = Token.at(await dao.token.call());
        await token.transfer(accounts[9], await token.balanceOf.call(unknownAccount));
    });

    beforeEach(async () => {
        await helper.payForVoting(dao, accounts[0]);
        const tx = await dao.addRegular(name, 'Test description', duration, ['yes', 'no', 'maybe']);
        const logs = helper.decodeVotingParameters(tx);
        regular = Regular.at(logs[0]);
    });

    const makeRegular = async (finish = true) => {
        await Promise.all([
            regular.addVote(1),
            regular.addVote(3, {from: unknownAccount}),
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [duration]);
        await helper.rpcCall(web3, "evm_mine", null);
        if (finish) await regular.finish();
    };

    it("Should add vote from 2 different accounts", async () => {
        const [, , latestBlock] = await Promise.all([
            regular.addVote(1),
            regular.addVote(3, {from: unknownAccount}),
            helper.getLatestBlock(web3)
        ]);

        const [option1, option2, balance1, balance2] = await Promise.all([
            regular.options.call(1),
            regular.options.call(3),
            token.balanceOf.call(serviceAccount),
            token.balanceOf.call(unknownAccount),
        ]);

        assert.equal(balance1.toNumber(), option1[0].toNumber());
        assert.equal(balance2.toNumber(), option2[0].toNumber());
        assert.equal(1, await regular.voted.call(serviceAccount));
        assert.equal(3, await regular.voted.call(unknownAccount));
        assert.equal(
            Math.round(web3.fromWei(balance1.toNumber() + balance2.toNumber())),
            Math.round(web3.fromWei((await regular.votesCount.call())))
        );
        assert.equal(latestBlock.timestamp + duration, (await token.held.call(serviceAccount)).toNumber());
        assert.equal(latestBlock.timestamp + duration, (await token.held.call(unknownAccount)).toNumber());
    });

    it("Should add vote from 3 different accounts", async () => {
        const [, , , latestBlock] = await Promise.all([
            regular.addVote(1),
            regular.addVote(2, {from: accounts[9]}),
            regular.addVote(3, {from: unknownAccount}),
            helper.getLatestBlock(web3)
        ]);

        const [option1, option2, option3, balance1, balance2, balance3] = await Promise.all([
            regular.options.call(1),
            regular.options.call(2),
            regular.options.call(3),
            await token.balanceOf.call(serviceAccount),
            await token.balanceOf.call(accounts[9]),
            await token.balanceOf.call(unknownAccount),
        ]);

        assert.equal(balance1.toNumber(), option1[0].toNumber());
        assert.equal(balance2.toNumber(), option2[0].toNumber());
        assert.equal(balance3.toNumber(), option3[0].toNumber());
        assert.equal(1, await regular.voted.call(serviceAccount));
        assert.equal(2, await regular.voted.call(accounts[9]));
        assert.equal(3, await regular.voted.call(unknownAccount));
        assert.equal(
            Math.round(web3.fromWei(balance1.toNumber() + balance2.toNumber() + balance3.toNumber())),
            Math.round(web3.fromWei((await regular.votesCount.call())))
        );
        assert.equal(latestBlock.timestamp + duration, (await token.held.call(serviceAccount)).toNumber());
        assert.equal(latestBlock.timestamp + duration, (await token.held.call(accounts[9])).toNumber());
        assert.equal(latestBlock.timestamp + duration, (await token.held.call(unknownAccount)).toNumber());
    });

    it("Should finish voting", async () => {
        await makeRegular();

        assert.equal(true, await regular.finished.call());
        assert.deepEqual(await regular.result.call(), await regular.options.call(1));
    });

    it("Should finish voting with identical votes for options", async () => {

        await Promise.all([
            await regular.addVote(1, {from: accounts[9]}),
            await regular.addVote(3, {from: unknownAccount}),
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [duration + 10]);
        await helper.rpcCall(web3, "evm_mine", null);
        await regular.finish();

        assert.equal(true, await regular.finished.call());
        assert.equal((await regular.result.call())[0], 0);
    });

    it("Should not be able to vote twice", async () => {
        await regular.addVote(1);

        return helper.handleErrorTransaction(() => regular.addVote(2));
    });

    it("Should not let create proposal if not enough DXC for voting price was transferred", async () => {
        const dxc = await helper.mintDXC(accounts[0], web3.toWei('0.09'));
        await dxc.contributeTo.sendTransaction(dao.address, web3.toWei('0.09'));

        return helper.handleErrorTransaction(() => dao.addRegular(name, 'Test description', duration, ['yes', 'no', 'maybe']));
    });

    it("Should not let create proposal if not enough DXC for voting price was transferred", async () => {
        await helper.payForVoting(dao, accounts[9]);

        return helper.handleErrorTransaction(() => dao.addRegular(name, 'Test description', duration, ['yes', 'no', 'maybe']));
    });

    it("Should not be able to vote after moment when voting was finished", async () => {
        await makeRegular();

        return helper.handleErrorTransaction(() => regular.addVote(2));
    });

    it("Should not be able to vote after moment when duration exceeded", async () => {
        await makeRegular(false);

        return helper.handleErrorTransaction(() => regular.addVote(2));
    });

    it("Should not be able to vote for nonexistent option", async () =>
        helper.handleErrorTransaction(() => regular.addVote(4)));

    it("Should not be able to finish voting twice", async () => {
        await makeRegular();

        return helper.handleErrorTransaction(() => regular.finish());
    });

    it("Should not be able to finish voting before the end", async () => {
        await helper.rpcCall(web3, "evm_increaseTime", [50]);
        await helper.rpcCall(web3, "evm_mine", null);

        return helper.handleErrorTransaction(() => regular.finish());
    });

    it("Should not create regular with duration < 7 days", async () => {
        duration = 0;

        return helper.handleErrorTransaction(() => makeRegular());
    });
});