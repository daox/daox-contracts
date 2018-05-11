"use strict";
const helper = require('../helpers/helper.js');
const Token = artifacts.require("./Token/Token.sol");
const Commission = artifacts.require("./Commission.sol");
const DXCToken = artifacts.require("./Token/DXC.sol");
const daoxContract = artifacts.require("./DAOx.sol");
const Refund = artifacts.require('./Votings/Refund.sol');

contract("Case#2", accounts => {
    const [serviceAccount] = [accounts[0]];
    const [teamMember1, teamMember2, teamMember3, teamMember4] = [accounts[2], accounts[3], accounts[4], accounts[5]];
    const team = [teamMember1, teamMember2, teamMember3, teamMember4];
    const teamBonuses = [4, 4, 4, 4];
    const [whiteListAddress1] = [teamMember4];
    const [backer1, backer2, backer3, backer4, backer5, backer6] = [accounts[6], accounts[7], accounts[8], accounts[9], accounts[10], accounts[11], accounts[12]];
    const [softCap, hardCap, etherRate, DXCRate, dxcPayment, commissionRate] = [1000, 2000, web3.toBigNumber(5000), 10, true, 0.04];
    const [dxcAmount1, dxcAmount2, dxcAmount3, dxcAmount4] = [
        web3.toBigNumber(web3.toWei(400000)),
        web3.toBigNumber(web3.toWei(200000)),
        web3.toBigNumber(web3.toWei(100000)),
        web3.toBigNumber(web3.toWei(40000))
    ];
    const [etherAmount1, etherAmount2] = [
        web3.toBigNumber(web3.toWei(153)),
        web3.toBigNumber(web3.toWei(33))
    ];
    const weiDeposited = etherAmount1.plus(etherAmount2);
    const dxcDeposited = dxcAmount1.plus(dxcAmount2).plus(dxcAmount3).plus(dxcAmount4);
    const [crowdsaleStartShift, crowdsaleFinishShift, bonusShift1, bonusEther1] = [24 * 60 * 60, 7 * 24 * 60 * 60, 2 * 24 * 60 * 60, etherRate.plus(500)];
    const SECONDS_PER_YEAR = 3.154e+7;

    let dao, cdf, token, DXC, DAOX, refund, etherBalanceAfterCrowdsale, dxcBalanceAfterCrowdsale;

    before(async () => {
        DXC = DXCToken.at(DXCToken.address);
        await Promise.all([
            helper.mintDXC(backer1, dxcAmount1),
            helper.mintDXC(backer2, dxcAmount2),
            helper.mintDXC(backer3, dxcAmount3),
            helper.mintDXC(backer4, dxcAmount4),
        ]);

        cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf, accounts);

        await dao.initBonuses(
            team,
            teamBonuses,
            [(await helper.getLatestBlock(web3)).timestamp + crowdsaleStartShift + bonusShift1],
            [bonusEther1],
            [],
            [SECONDS_PER_YEAR, SECONDS_PER_YEAR, SECONDS_PER_YEAR, SECONDS_PER_YEAR],
            [false, false, false, false]
        );
        await dao.setWhiteList([whiteListAddress1]);
        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3, true,
            [
                softCap,
                hardCap,
                etherRate.toNumber(),
                DXCRate,
                (await helper.getLatestBlock(web3)).timestamp + crowdsaleStartShift,
                (await helper.getLatestBlock(web3)).timestamp + crowdsaleFinishShift,
                dxcPayment
            ]);

        const commissionContract = Commission.at(await dao.commissionContract());

        await helper.rpcCall(web3, "evm_increaseTime", [crowdsaleStartShift]);
        await helper.rpcCall(web3, "evm_mine", null);

        await Promise.all([
            commissionContract.sendTransaction({from: backer5, value: etherAmount1}),
            commissionContract.sendTransaction({from: backer6, value: etherAmount2})
        ]);

        await Promise.all([
            DXC.contributeTo(dao.address, dxcAmount1, {from: backer1}),
            DXC.contributeTo(dao.address, dxcAmount2, {from: backer2}),
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [bonusShift1]);
        await helper.rpcCall(web3, "evm_mine", null);

        await Promise.all([
            DXC.contributeTo(dao.address, dxcAmount3, {from: backer3}),
            DXC.contributeTo(dao.address, dxcAmount4, {from: backer4}),
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [crowdsaleFinishShift - bonusShift1]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.finish();
        token = Token.at(await dao.token());
        DAOX = daoxContract.at(await dao.serviceContract());
        etherBalanceAfterCrowdsale = await helper.getBalance(web3, dao.address);
        dxcBalanceAfterCrowdsale = await DXC.balanceOf(dao.address);
    });

    it("Bonus token should be minted correct", async () => {
        assert.deepEqual(await token.balanceOf(backer5), etherAmount1.times(bonusEther1));
        assert.deepEqual(await token.balanceOf(backer6), etherAmount2.times(bonusEther1));
    });

    it("Common tokens should be minted correct", async () => {
        assert.deepEqual(await token.balanceOf(backer1), dxcAmount1.times(DXCRate));
        assert.deepEqual(await token.balanceOf(backer2), dxcAmount2.times(DXCRate));
        assert.deepEqual(await token.balanceOf(backer3), dxcAmount3.times(DXCRate));
        assert.deepEqual(await token.balanceOf(backer4), dxcAmount4.times(DXCRate));
    });

    it("Tokens amount related properties should be calculated correct", async () => {
        const tokensMintedByEther = weiDeposited.times(bonusEther1);
        const tokensMintedByDXC = dxcDeposited.times(DXCRate);

        assert.deepEqual(await dao.tokensMintedByEther(), tokensMintedByEther);
        assert.deepEqual(await dao.tokensMintedByDXC(), tokensMintedByDXC);
    });

    it("Team tokens should be minted correct", async () => {
        const [tokensMintedByEther, tokensMintedByDXC] = await Promise.all([
            dao.tokensMintedByEther(),
            dao.tokensMintedByDXC()
        ]);

        assert.deepEqual(await token.balanceOf(teamMember1), tokensMintedByEther.plus(tokensMintedByDXC).dividedBy(100).times(teamBonuses[0]));
        assert.deepEqual(await token.balanceOf(teamMember2), tokensMintedByEther.plus(tokensMintedByDXC).dividedBy(100).times(teamBonuses[1]));
        assert.deepEqual(await token.balanceOf(teamMember3), tokensMintedByEther.plus(tokensMintedByDXC).dividedBy(100).times(teamBonuses[2]));
        assert.deepEqual(await token.balanceOf(teamMember4), tokensMintedByEther.plus(tokensMintedByDXC).dividedBy(100).times(teamBonuses[3]));
    });

    it("Should not create refund with duration < 7 days", async () => {
        const withdrawalDuration = web3.toBigNumber(6 * 24 * 60 * 60);
        return helper.handleErrorTransaction(() =>
            dao.addRefund(
                "Refund#1",
                "Project could be not implemented#1",
                withdrawalDuration.toNumber(),
                {from: backer1}
            )
        );
    });

    it("Refund should be accepted", async () => {
        const withdrawalDuration = web3.toBigNumber(7 * 24 * 60 * 60);
        const tx = await dao.addRefund("Refund#2", "Project could", withdrawalDuration.toNumber(), {from: backer2});
        const logs = helper.decodeVotingParameters(tx);
        refund = Refund.at(logs[0]);

        await refund.addVote(1, {from: backer1});
        await refund.addVote(1, {from: backer2});
        await refund.addVote(1, {from: backer3});
        await refund.addVote(1, {from: backer4});
        await refund.addVote(1, {from: backer6});

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await refund.finish();

        assert.deepEqual(await refund.result(), await refund.options(1));
    });

    it("Tokens should be burned after refund", async () => {
        await Promise.all([
            dao.refund({from: backer1}),
            dao.refund({from: backer2}),
            dao.refund({from: backer3}),
            dao.refund({from: backer4}),
            dao.refund({from: backer5}),
            dao.refund({from: backer6}),
        ]);

        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer1));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer2));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer3));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer4));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer5));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer6));
    });

    it("Balance after refund should be correct", async () => {
        assert.isTrue(await helper.getBalance(web3, dao.address) / etherBalanceAfterCrowdsale * 100 <= 1.5);
        assert.isTrue(await DXC.balanceOf(dao.address) / dxcBalanceAfterCrowdsale * 100 <= 1.5);
    });
});