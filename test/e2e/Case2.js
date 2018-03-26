"use strict";
const helper = require('../helpers/helper.js');
const Token = artifacts.require("./Token/Token.sol");
const Commission = artifacts.require("./Commission.sol");
const DXCToken = artifacts.require("./Token/DXC.sol");
const daoxContract = artifacts.require("./DAOX.sol");
const Withdrawal = artifacts.require('./Votings/Withdrawal.sol');
const Refund = artifacts.require('./Votings/Refund.sol');

contract("Case#2", account => {
    const [serviceAccount] = [accounts[0]];
    const [teamPerson1, teamPerson2, teamPerson3, teamPerson4] = [accounts[2], accounts[3], accounts[4], accounts[5]];
    const team = [teamPerson1, teamPerson2, teamPerson3, teamPerson4];
    const teamBonuses = [4, 4, 4, 4];
    const [whiteListAddress1] = [teamPerson4];
    const [backer1, backer2, backer3, backer4, backer5, backer6] = [accounts[6], accounts[7], accounts[8], accounts[9], accounts[10], accounts[11], accounts[12]];
    const [softCap, hardCap, etherRate, DXCRate, dxcPayment, commissionRate] = [1000, 2000, web3.toBigNumber(5000), 10, true, 0.04];
    const [dxcAmount1, dxcAmount2, dxcAmount3, dxcAmount4] = [
        web3.toBigNumber(web3.toWei(40000)),
        web3.toBigNumber(web3.toWei(20000)),
        web3.toBigNumber(web3.toWei(10000)),
        web3.toBigNumber(web3.toWei(4000))
    ];
    const [etherAmount1, etherAmount2] = [
        web3.toBigNumber(web3.toWei(153)),
        web3.toBigNumber(web3.toWei(33)),
    ];
    const weiDeposited = etherAmount1.plus(etherAmount2);
    const dxcDeposited = dxcAmount1.plus(dxcAmount2).plus(dxcAmount3).plus(dxcAmount4);
    const [crowdsaleStartShift, crowdsaleFinishShift, bonusShift1, bonusEther1]= [24 * 60 * 60, 7 * 24 * 60 * 60, 2 * 24 * 60 * 60, etherRate + 500];

    let dao, cdf, token, DXC, DAOX, newEtherRate, newDXCRate;

    before(async () => {
        const block = await helper.getLatestBlock(web3);
        DXC = DXCToken.at(DXCToken.address);
        await Promise.all([
            DXC.mint(backer5, dxcAmount1),
            DXC.mint(backer6, dxcAmount2)
        ]);

        cdf = await helper.createCrowdsaleDAOFactory();
        dao = await helper.createCrowdsaleDAO(cdf, accounts);

        await dao.initBonuses(team, teamBonuses, [block.timestamp + bonusShift1], [5500], [], [10000, 10000], [false, false]);
        await dao.setWhiteList([whiteListAddress1]);
        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3, true,
            [
                softCap,
                hardCap,
                etherRate.toNumber(),
                DXCRate,
                block.timestamp + crowdsaleStartShift,
                block.timestamp + crowdsaleFinishShift,
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
    });

});