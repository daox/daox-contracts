"use strict";
const helper = require('../helpers/helper.js');
const Token = artifacts.require("./Token/Token.sol");
const Commission = artifacts.require("./Commission.sol");
const DXCToken = artifacts.require("./Token/DXC.sol");
const daoxContract = artifacts.require("./DAOx.sol");
const Withdrawal = artifacts.require('./Votings/Withdrawal.sol');
const Refund = artifacts.require('./Votings/Refund.sol');

contract("Case#1", accounts => {

    const [serviceAccount] = [accounts[0]];
    const [teamPerson1, teamPerson2] = [accounts[2], accounts[3]];
    const team = [teamPerson1, teamPerson2];
    const teamBonuses = [4, 5];
    const [whiteListAddress1] = [accounts[4]];
    const [backer1, backer2, backer3, backer4, backer5, backer6] = [accounts[5], accounts[6], accounts[7], accounts[8], accounts[9], accounts[1]];
    const [softCap, hardCap, etherRate, DXCRate, dxcPayment, commissionRate] = [1, 20, web3.toBigNumber(1000), 1, true, 0.04];
    const [dxcAmount1, dxcAmount2] = [
        web3.toBigNumber(web3.toWei(4100)),
        web3.toBigNumber(web3.toWei(3198))
    ];
    const [etherAmount1, etherAmount2, etherAmount3, etherAmount4] = [
        web3.toBigNumber(web3.toWei(1.3)),
        web3.toBigNumber(web3.toWei(0.955)),
        web3.toBigNumber(web3.toWei(0.332)),
        web3.toBigNumber(web3.toWei(10.1))
    ];
    const weiDeposited = etherAmount1.plus(etherAmount2).plus(etherAmount3).plus(etherAmount4);
    const dxcDeposited = dxcAmount1.plus(dxcAmount2);

    let dao, cdf, token, DXC, DAOX, newEtherRate, newDXCRate, etherBalanceAfterCrowdsale, dxcBalanceAfterCrowdsale;

    before(async () => {
        DXC = DXCToken.at(DXCToken.address);
        await Promise.all([
            DXC.mint(backer5, dxcAmount1),
            DXC.mint(backer6, dxcAmount2)
        ]);

        cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf, accounts);

        await dao.initBonuses(team, teamBonuses, [], [], [], [10000, 10000], [false, false]);
        await dao.setWhiteList([whiteListAddress1]);
        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3, true,
            [
                softCap,
                hardCap,
                etherRate.toNumber(),
                DXCRate,
                (await helper.getLatestBlock(web3)).timestamp + 60,
                (await helper.getLatestBlock(web3)).timestamp + 120,
                dxcPayment
            ]);

        const commissionContract = Commission.at(await dao.commissionContract());

        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        await Promise.all([
            commissionContract.sendTransaction({from: backer1, value: etherAmount1}),
            commissionContract.sendTransaction({from: backer2, value: etherAmount2}),
            commissionContract.sendTransaction({from: backer3, value: etherAmount3}),
            commissionContract.sendTransaction({from: backer4, value: etherAmount4}),
        ]);

        await Promise.all([
            DXC.contributeTo(dao.address, dxcAmount1, {from: backer5}),
            DXC.contributeTo(dao.address, dxcAmount2, {from: backer6}),
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.finish();
        token = Token.at(await dao.token());
        DAOX = daoxContract.at(await dao.serviceContract());
        etherBalanceAfterCrowdsale = await helper.getBalance(web3, dao.address);
        dxcBalanceAfterCrowdsale = web3.toBigNumber(await DXC.balanceOf(dao.address)).minus(await dao.initialCapital());
    });


    it("tokens distribution after crowdsale should be correct", async () => {
        assert.deepEqual(etherAmount1.times(etherRate), await token.balanceOf(backer1));
        assert.deepEqual(etherAmount2.times(etherRate), await token.balanceOf(backer2));
        assert.deepEqual(etherAmount3.times(etherRate), await token.balanceOf(backer3));
        assert.deepEqual(etherAmount4.times(etherRate), await token.balanceOf(backer4));

        assert.deepEqual(dxcAmount1.times(DXCRate), await token.balanceOf(backer5));
        assert.deepEqual(dxcAmount2.times(DXCRate), await token.balanceOf(backer6));

        const tokensShouldBeMintedByEther = weiDeposited.times(etherRate);
        const tokensShouldBeMintedByDXC = dxcDeposited.times(DXCRate);

        assert.deepEqual(tokensShouldBeMintedByEther, await dao.tokensMintedByEther());
        assert.deepEqual(tokensShouldBeMintedByDXC, await dao.tokensMintedByDXC());

        assert.deepEqual(tokensShouldBeMintedByEther.plus(tokensShouldBeMintedByDXC).times(teamBonuses[0] / 100), await token.balanceOf(teamPerson1));
        assert.deepEqual(tokensShouldBeMintedByEther.plus(tokensShouldBeMintedByDXC).times(teamBonuses[1] / 100), await token.balanceOf(teamPerson2));
    });

    it("Commission should be calculated correct", async () => {
        assert.deepEqual(weiDeposited, await dao.weiRaised());
        assert.deepEqual(weiDeposited, await dao.commissionRaised());
        assert.deepEqual(weiDeposited.times(commissionRate), await DAOX.balance());
        assert.deepEqual(weiDeposited.times(1 - commissionRate), web3.toBigNumber(await helper.getBalance(web3, dao.address, false)));
    });

    it("Commission should be withdrawable", async () => {
        const serviceBalanceBefore = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, serviceAccount)));

        await DAOX.withdraw.sendTransaction(weiDeposited.times(commissionRate), {from: serviceAccount, gasPrice: 0});

        const serviceBalanceAfter = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, serviceAccount)));

        assert.deepEqual(weiDeposited.times(commissionRate).plus(serviceBalanceBefore), serviceBalanceAfter);
        assert.deepEqual(web3.toBigNumber(0), await DAOX.balance());
    });

    it("Should not accept withdraw", async () => {
        const withdrawalDuration = web3.toBigNumber(7 * 24 * 60 * 60);
        const withdrawalSum = web3.toBigNumber(web3.toWei(8.99));
        const daoBalanceBefore = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, dao.address)));

        const tx = await dao.addWithdrawal("Withdrawal#1", "Salary withdrawal", withdrawalDuration.toNumber(), withdrawalSum.toNumber(), whiteListAddress1, false, {from: teamPerson1});
        const logs = helper.decodeVotingParameters(tx);
        const withdrawal = Withdrawal.at(logs[0]);

        await Promise.all([
            withdrawal.addVote(1, {from: backer1}),
            withdrawal.addVote(2, {from: backer2}),
            withdrawal.addVote(2, {from: backer3}),
        ]);

        assert.deepEqual(web3.toBigNumber(0), await token.held(backer4));
        assert.deepEqual(web3.toBigNumber(0), await token.held(backer5));
        assert.deepEqual(web3.toBigNumber(0), await token.held(backer6));

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.dividedBy(2).toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await Promise.all([
            withdrawal.addVote(2, {from: backer4}),
            withdrawal.addVote(2, {from: backer5}),
            withdrawal.addVote(2, {from: backer6}),
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.dividedBy(2).toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await withdrawal.finish();

        const daoBalanceAfter = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, dao.address)));

        assert.deepEqual(etherAmount1.times(etherRate), (await withdrawal.options(1))[0]);
        assert.deepEqual(weiDeposited.minus(etherAmount1).times(etherRate).plus(dxcDeposited.times(DXCRate)), (await withdrawal.options(2))[0]);
        assert.deepEqual(weiDeposited.minus(etherAmount1).times(etherRate).plus(dxcDeposited.times(DXCRate)), (await withdrawal.result())[0]);
        assert.deepEqual(daoBalanceBefore, daoBalanceAfter);
    });

    it("Should accept withdraw in ether", async () => {
        const withdrawalDuration = web3.toBigNumber(7 * 24 * 60 * 60);
        const withdrawalSum = web3.toBigNumber(web3.toWei(5.555));
        const daoBalanceBefore = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, dao.address)));
        const whiteListBalanceBefore = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, whiteListAddress1)));

        const tx = await dao.addWithdrawal("Withdrawal#2", "Salary withdrawal2", withdrawalDuration.toNumber(), withdrawalSum.toNumber(), whiteListAddress1, false, {from: teamPerson1});
        const logs = helper.decodeVotingParameters(tx);
        const withdrawal = Withdrawal.at(logs[0]);

        await Promise.all([
            withdrawal.addVote(1, {from: backer1}),
            withdrawal.addVote(1, {from: backer2}),
            withdrawal.addVote(1, {from: backer3}),
        ]);

        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer1));
        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer2));
        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer3));

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.dividedBy(2).toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await Promise.all([
            withdrawal.addVote(1, {from: backer4}),
            withdrawal.addVote(2, {from: backer5}),
            withdrawal.addVote(2, {from: backer6}),
        ]);

        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer1));
        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer2));
        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer3));
        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer4));
        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer5));
        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer6));

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.dividedBy(2).toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await withdrawal.finish();

        const daoBalanceAfter = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, dao.address)));
        const whiteListBalanceAfter = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, whiteListAddress1)));

        assert.deepEqual(weiDeposited.times(etherRate), (await withdrawal.options(1))[0]);
        assert.deepEqual(dxcDeposited.times(DXCRate), (await withdrawal.options(2))[0]);
        assert.deepEqual(weiDeposited.times(etherRate), (await withdrawal.result())[0]);
        assert.deepEqual(daoBalanceBefore.minus(withdrawalSum), daoBalanceAfter);
        assert.deepEqual(whiteListBalanceBefore.plus(withdrawalSum), whiteListBalanceAfter);
    });

    it("Should accept withdraw in dxc", async () => {
        const withdrawalDuration = web3.toBigNumber(14 * 24 * 60 * 60);
        const withdrawalSum = dxcAmount2;
        const daoBalanceBefore = web3.toBigNumber(await DXC.balanceOf(dao.address)).minus(await dao.initialCapital());
        const whiteListBalanceBefore = await DXC.balanceOf(whiteListAddress1);

        const tx = await dao.addWithdrawal("Withdrawal#3", "Salary withdrawal3", withdrawalDuration.toNumber(), withdrawalSum.toNumber(), whiteListAddress1, true, {from: teamPerson2});
        const logs = helper.decodeVotingParameters(tx);
        const withdrawal = Withdrawal.at(logs[0]);

        await withdrawal.addVote(1, {from: backer1});

        assert.deepEqual((await withdrawal.created_at()).plus(withdrawalDuration), await token.held(backer1));
        assert.deepEqual(await token.balanceOf(backer1), (await withdrawal.options(1))[0]);

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await withdrawal.finish();

        const daoBalanceAfter = web3.toBigNumber(await DXC.balanceOf(dao.address)).minus(await dao.initialCapital());

        assert.deepEqual(await token.balanceOf(backer1), (await withdrawal.result())[0]);
        assert.deepEqual(daoBalanceBefore.minus(withdrawalSum), daoBalanceAfter);
        assert.deepEqual(whiteListBalanceBefore.plus(withdrawalSum), withdrawalSum);
    });

    it("Should not accept refund when amount of positive votes <= 90%", async () => {
        const withdrawalDuration = web3.toBigNumber(14 * 24 * 60 * 60);
        await helper.payForVoting(dao, backer1);
        const tx = await dao.addRefund("Refund#1", "Project could be not implemented", withdrawalDuration.toNumber(), {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const refund = Refund.at(logs[0]);


        // Quorum here is ~88%

        await refund.addVote(1, {from: backer4});
        await refund.addVote(1, {from: backer5});
        await refund.addVote(1, {from: backer6});
        await refund.addVote(1, {from: backer3});

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await refund.finish();

        const [tokenAmount1, tokenAmount2, tokenAmount3, tokenAmount4] = await Promise.all([
            token.balanceOf(backer4),
            token.balanceOf(backer5),
            token.balanceOf(backer6),
            token.balanceOf(backer3)
        ]);

        const tokensVoted = tokenAmount1.plus(tokenAmount2).plus(tokenAmount3).plus(tokenAmount4);

        assert.deepEqual(tokensVoted, (await refund.options(1))[0]);
        assert.deepEqual(web3.toBigNumber(0), (await refund.result())[0]);
        assert.isFalse(await dao.refundable());
    });

    it("Should accept refund when amount of positive votes >= 90%", async () => {
        const daoEtherBalance = web3.toBigNumber(web3.toWei(await helper.getBalance(web3, dao.address)));
        const daoDXCBalance = (await DXC.balanceOf(dao.address)).minus(await dao.initialCapital());

        const withdrawalDuration = web3.toBigNumber(7 * 24 * 60 * 60);
        await helper.payForVoting(dao, backer1);
        const tx = await dao.addRefund("Refund#2", "Project could be not implemented#2", withdrawalDuration.toNumber(), {from: backer1});
        const logs = helper.decodeVotingParameters(tx);
        const refund = Refund.at(logs[0]);


        await refund.addVote(1, {from: backer1});
        await refund.addVote(2, {from: backer2});
        await refund.addVote(1, {from: backer3});
        await refund.addVote(1, {from: backer4});
        await refund.addVote(1, {from: backer5});
        await refund.addVote(1, {from: backer6});

        await helper.rpcCall(web3, "evm_increaseTime", [withdrawalDuration.toNumber()]);
        await helper.rpcCall(web3, "evm_mine", null);

        await refund.finish();

        const [tokenAmount1, tokenAmount2, tokenAmount3, tokenAmount4, tokenAmount5, tokenAmount6] = await Promise.all([
            token.balanceOf(backer1),
            token.balanceOf(backer2),
            token.balanceOf(backer3),
            token.balanceOf(backer4),
            token.balanceOf(backer5),
            token.balanceOf(backer6),
        ]);

        const tokensVotedForOption1 = tokenAmount1.plus(tokenAmount3).plus(tokenAmount4).plus(tokenAmount5).plus(tokenAmount6);
        const tokensVotedForOption2 = tokenAmount2;
        newEtherRate = daoEtherBalance.times(etherRate).times(web3.toBigNumber(100000)).dividedBy(weiDeposited.times(web3.toBigNumber(etherRate))).round();
        newDXCRate = daoDXCBalance.times(DXCRate).times(100000).dividedBy(dxcDeposited.times(DXCRate)).round();

        assert.deepEqual(tokensVotedForOption1, (await refund.options(1))[0]);
        assert.deepEqual(tokensVotedForOption2, (await refund.options(2))[0]);
        assert.deepEqual(tokensVotedForOption1, (await refund.result())[0]);
        assert.isTrue(await dao.refundable());
        assert.deepEqual(newEtherRate, await dao.newEtherRate());
        assert.deepEqual(newDXCRate, await dao.newDXCRate());
    });

    it("All token holders should refund correct amount of ether/dxc", async () => {
        // All dxc balances equal 0 before refund
        const dxcDAOBalanceBefore = await DXC.balanceOf(dao.address) - await dao.initialCapital(); // 4.1e+21
        const etherDAOBalanceBefore = await helper.getBalance(web3, dao.address); //6.62452

        const [etherBalanceBefore1, etherBalanceBefore2, etherBalanceBefore3, etherBalanceBefore4, etherBalanceBefore5, etherBalanceBefore6] = await Promise.all([
            helper.getBalance(web3, backer1),
            helper.getBalance(web3, backer2),
            helper.getBalance(web3, backer3),
            helper.getBalance(web3, backer4),
            helper.getBalance(web3, backer5),
            helper.getBalance(web3, backer6)
        ]);

        const [tokensAmount1, tokensAmount2, tokensAmount3, tokensAmount4, tokensAmount5, tokensAmount6] = await Promise.all([
            token.balanceOf(backer1),
            token.balanceOf(backer2),
            token.balanceOf(backer3),
            token.balanceOf(backer4),
            token.balanceOf(backer5),
            token.balanceOf(backer6)
        ]);


        await dao.refund({from: backer1});
        const [etherBalanceAfter1, dxcBalanceAfter1] = await Promise.all([
            helper.getBalance(web3, backer1), // 0.42009844999999757
            DXC.balanceOf(backer1) // 0.26291772
        ]);


        const refundSum1 = etherBalanceAfter1 - etherBalanceBefore1 + parseFloat(web3.fromWei(dxcBalanceAfter1 / 1000));
        //0,7496642283 should be
        //0,68301617 actual

        await dao.refund({from: backer2});
        const [etherBalanceAfter2, dxcBalanceAfter2] = await Promise.all([
            helper.getBalance(web3, backer2), // 0.3066091474999979
            DXC.balanceOf(backer2) // 0.193143402
        ]);

        const refundSum2 = etherBalanceAfter2 - etherBalanceBefore2 + parseFloat(web3.fromWei(dxcBalanceAfter2 / 1000));
        //0,5507148754 should be
        //0,4997525495 actual

        await dao.refund({from: backer3});
        const [etherBalanceAfter3, dxcBalanceAfter3] = await Promise.all([
            helper.getBalance(web3, backer3), // 0.10167049400000394
            DXC.balanceOf(backer3) // 0.0671451408
        ]);

        const refundSum3 = etherBalanceAfter3 - etherBalanceBefore3 + parseFloat(web3.fromWei(dxcBalanceAfter3 / 1000));
        //0,1914527106 should be
        //0,1688156348 actual

        await dao.refund({from: backer4});
        const [etherBalanceAfter4, dxcBalanceAfter4] = await Promise.all([
            helper.getBalance(web3, backer4), // 3.3148980499999965
            DXC.balanceOf(backer4) // 2.04266844
        ]);

        const refundSum4 = etherBalanceAfter4 - etherBalanceBefore4 + parseFloat(web3.fromWei(dxcBalanceAfter4 / 1000));
        //5,8243143891 should be
        //5,35756649 actual

        await dao.refund({from: backer5});
        const [etherBalanceAfter5, dxcBalanceAfter5] = await Promise.all([
            helper.getBalance(web3, backer5), // 1.3411710499999998
            DXC.balanceOf(backer5) // 0.8292020400000001
        ]);

        const refundSum5 = etherBalanceAfter5 - etherBalanceBefore5 + parseFloat(web3.fromWei(dxcBalanceAfter5 / 1000));
        //2,3643256431 should be
        //2,17037309 actual

        await dao.refund({from: backer6});
        const [etherBalanceAfter6, dxcBalanceAfter6] = await Promise.all([
            helper.getBalance(web3, backer6), // 1.0444540910000057
            DXC.balanceOf(backer6) // 0.6467775912
        ]);

        const refundSum6 = etherBalanceAfter6 - etherBalanceBefore6 + parseFloat(web3.fromWei(dxcBalanceAfter6 / 1000));
        //1,8441740016 should be
        //1,6912316822 actual


        //0.0503643175 dao ether balance
        //0.058145666 dao dxc balance
        //0,1085099835 left

        //10,6792656 left + refunded
    });

    it("Tokens should be burned after refund", async () => {
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer1));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer2));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer3));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer4));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer5));
        assert.deepEqual(web3.toBigNumber(0), await token.balanceOf(backer6));
    });

    it("Balance after refund should be correct", async () => {
        assert.isTrue(await helper.getBalance(web3, dao.address) / etherBalanceAfterCrowdsale * 100 <= 1.5);
        assert.isTrue(web3.toBigNumber(await DXC.balanceOf(dao.address)).minus(await dao.initialCapital()) / dxcBalanceAfterCrowdsale * 100 <= 1.5);
    });
});