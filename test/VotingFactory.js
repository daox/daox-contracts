"use strict";
const helper = require('./helpers/helper.js');
const Proposal = artifacts.require('./Votings/Proposal.sol');
const Withdrawal = artifacts.require('./Votings/Withdrawal.sol');
const Refund = artifacts.require('./Votings/Refund.sol');
const Module = artifacts.require('./Votings/Module.sol');
const VotingFactory = artifacts.require('./Votings/VotingFactory.sol');

contract("CrowdsaleDAO", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];

    let cdf, dao;
    before(async () => {
        cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf);
        await dao.setWhiteList.sendTransaction([serviceAccount]);
        await helper.makeCrowdsale(web3, cdf, dao, serviceAccount);
    });

    it("Should create proposal", async () => {
        const description = 'Test Description';
        const tx = await dao.addProposal(description, 100, ['yes', 'no', 'maybe']);
        const logs = helper.decodeVotingParameters(tx);
        const proposal = Proposal.at(logs[0]);

        const [option1, option2, option3] = await Promise.all([
            proposal.options.call(1),
            proposal.options.call(2),
            proposal.options.call(3)
        ]);

        assert.equal(helper.fillZeros(web3.toHex(description)), await proposal.description.call());
        assert.equal(helper.fillZeros(web3.toHex('yes')), option1[1]);
        assert.equal(helper.fillZeros(web3.toHex('no')), option2[1]);
        assert.equal(helper.fillZeros(web3.toHex('maybe')), option3[1]);
        assert.equal(100, await proposal.duration.call());
        assert.equal(false, await proposal.finished.call());
    });

    it("Should create withdrawal", async () => {
        const description = 'Test Description';
        const tx = await dao.addWithdrawal(description, 100, web3.toWei(1), serviceAccount);
        const logs = helper.decodeVotingParameters(tx);
        const withdrawal = Withdrawal.at(logs[0]);

        const [option1, option2] = await Promise.all([
            withdrawal.options.call(1),
            withdrawal.options.call(2)
        ]);

        assert.equal(helper.fillZeros(web3.toHex(description)), await withdrawal.description.call());
        assert.equal(helper.fillZeros(web3.toHex('yes')), option1[1]);
        assert.equal(helper.fillZeros(web3.toHex('no')), option2[1]);
        assert.equal(100, await withdrawal.duration.call());
        assert.equal(web3.toWei(1), await withdrawal.withdrawalSum.call());
        assert.equal(serviceAccount, await withdrawal.withdrawalWallet.call());
        assert.equal(false, await withdrawal.finished.call());
    });

    it("Should create refund", async () => {
        const description = 'Test Description';
        const tx = await dao.addRefund(description, 100);
        const logs = helper.decodeVotingParameters(tx);
        const refund = Refund.at(logs[0]);

        const [option1, option2] = await Promise.all([
            refund.options.call(1),
            refund.options.call(2),
        ]);

        assert.equal(helper.fillZeros(web3.toHex(description)), await refund.description.call());
        assert.equal(helper.fillZeros(web3.toHex('yes')), option1[1]);
        assert.equal(helper.fillZeros(web3.toHex('no')), option2[1]);
        assert.equal(100, await refund.duration.call());
        assert.equal(false, await refund.finished.call());
    });

    it("Should create module", async () => {
        const description = 'Test Description';
        const tx = await dao.addModule(description, 100, 1, unknownAccount);
        const logs = helper.decodeVotingParameters(tx);
        const module = Module.at(logs[0]);

        const [option1, option2] = await Promise.all([
            module.options.call(1),
            module.options.call(2),
        ]);

        assert.equal(helper.fillZeros(web3.toHex(description)), await module.description.call());
        assert.equal(helper.fillZeros(web3.toHex('yes')), option1[1]);
        assert.equal(helper.fillZeros(web3.toHex('no')), option2[1]);
        assert.equal(100, await module.duration.call());
        assert.equal(1, await module.module.call());
        assert.equal(unknownAccount, await module.newModuleAddress.call());
        assert.equal(false, await module.finished.call());
    });

    it("Should not be able to create any voting from not participant", async () => {
        const description = 'Test Description';

        await Promise.all([
            helper.handleErrorTransaction(async () => await dao.addModule(description, 100, 1, unknownAccount, {from: unknownAccount})),
            helper.handleErrorTransaction(async () => await dao.addRefund(description, 100, {from: unknownAccount})),
            helper.handleErrorTransaction(async () => await dao.addWithdrawal(description, 100, 1, serviceAccount, {from: unknownAccount})),
            helper.handleErrorTransaction(async () => await dao.addProposal(description, 100, ['yes', 'no', 'maybe'], {from: unknownAccount})),
        ]);
    });

    it("Should not be able to create any voting from not dao", async () => {
        const description = 'Test Description';
        const votingFactory = VotingFactory.at(await dao.votingFactory.call());

        await Promise.all([
            helper.handleErrorTransaction(async () => await votingFactory.addModule(serviceAccount, description, 100, 1, unknownAccount)),
            helper.handleErrorTransaction(async () => await votingFactory.addRefund(serviceAccount, description, 100)),
            helper.handleErrorTransaction(async () => await votingFactory.addWithdrawal(serviceAccount, description, 100, 1, serviceAccount)),
            helper.handleErrorTransaction(async () => await votingFactory.addProposal(serviceAccount, description, 100, ['yes', 'no', 'maybe'])),
        ]);
    });

    it("Should not be able to create withdrawal with wallet which is not in white list", async () => {
        const description = 'Test Description';

        await helper.handleErrorTransaction(async () => await dao.addWithdrawal(description, 100, 1, unknownAccount));
    });

    it("Should not be able to create withdrawal with zero sum", async () => {
        const description = 'Test Description';

        await helper.handleErrorTransaction(async () => await dao.addWithdrawal(description, 100, 0, serviceAccount));
    });

    it("Should not be able to create withdrawal with sum more than dao balance", async () => {
        const description = 'Test Description';

        await helper.handleErrorTransaction(async () => await dao.addWithdrawal(description, 100, web3.toWei(11), serviceAccount));
    });

    it("Should not be able to create proposal with less than 2 options", async () => {
        const description = 'Test Description';

        await helper.handleErrorTransaction(async () => await dao.addProposal(description, 100, ['yes']));
    });

    it("Should not be able to create withdrawal with more than 10 options", async () => {
        const description = 'Test Description';

        await helper.handleErrorTransaction(async () =>
            await dao.addProposal(description, 100, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11']));
    });

    it("Should not be able to create any voting before succeeded crowdsale", async () => {
        const description = 'Test Description';

        const daoTest = await helper.createCrowdsaleDAO(cdf);
        await daoTest.setWhiteList.sendTransaction([serviceAccount]);
        await helper.makeCrowdsale(web3, cdf, daoTest, serviceAccount, false);

        await Promise.all([
            helper.handleErrorTransaction(async () => await daoTest.addModule(description, 100, 1, unknownAccount)),
            helper.handleErrorTransaction(async () => await daoTest.addRefund(description, 100)),
            helper.handleErrorTransaction(async () => await daoTest.addWithdrawal(description, 100, 1, serviceAccount)),
            helper.handleErrorTransaction(async () => await daoTest.addProposal(description, 100, ['yes', 'no', 'maybe'])),
        ]);
    });
});