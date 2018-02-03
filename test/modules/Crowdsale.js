"use strict";
const helper = require('../helpers/helper.js');
const Token = artifacts.require("./Token/Token.sol");
const Commission = artifacts.require("./Commission.sol");

contract("Crowdsale", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];

    let cdf, dao;

    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => dao = await helper.createCrowdsaleDAO(cdf));

    it("Should set parameters for crowdsale", async () => {
        const latestBlock = await helper.getLatestBlock(web3);
        const [softCap, hardCap, rate, startTime, endTime] = [100, 200, 1000, latestBlock.timestamp + 60, latestBlock.timestamp + 120];

        await dao.initCrowdsaleParameters.sendTransaction(softCap, hardCap, rate, startTime, endTime, {
            from: serviceAccount
        });

        const [contractSF, contractHC] = await Promise.all([dao.softCap.call(), dao.hardCap.call()]);
        assert.equal(web3.toWei(softCap, 'ether'), contractSF.toString());
        assert.equal(web3.toWei(hardCap, 'ether'), contractHC.toString());
        assert.equal(rate, await dao.rate.call());
        assert.equal(startTime, await dao.startTime.call());
        assert.equal(endTime, await dao.endTime.call());
    });

    it("Should not be able to set parameters for crowdsale from unknown account", async () => {
        const latestBlock = await helper.getLatestBlock(web3);
        const data = [100, 200, 1000, latestBlock.timestamp + 60, latestBlock.timestamp + 120];

        helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, unknownAccount, web3, data));
    });

    it("Should not be able to set parameters for crowdsale when start time already passed", async () => {
        const latestBlock = await helper.getLatestBlock(web3);
        const data = [100, 200, 1000, latestBlock.timestamp - 1, latestBlock.timestamp + 120];

        helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, serviceAccount, web3, data));
    });

    it("Should not be able to set parameters for crowdsale twice", async () => {
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);

        helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, serviceAccount, web3));
    });

    it("Should not be able to set parameters for crowdsale when softCap is bigger then hardCap time already passed", async () => {
        const latestBlock = await helper.getLatestBlock(web3);
        const data = [200, 100, 1000, latestBlock.timestamp + 60, latestBlock.timestamp + 120];

        helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, serviceAccount, web3, data));
    });

    it("Should deposit ether and mint tokens", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({from: unknownAccount, value: weiAmount});

        const token = Token.at(await dao.token.call());
        assert.equal(weiAmount, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount), "ether"));
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.totalSupply.call(), "ether"));
    });

    it("Should deposit ether and mint tokens for 2 accounts", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await Promise.all([
            dao.sendTransaction({from: unknownAccount, value: weiAmount}),
            dao.sendTransaction({from: serviceAccount, value: weiAmount})
        ]);

        const token = Token.at(await dao.token.call());
        assert.equal(weiAmount * 2, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(weiAmount, await dao.depositedWei.call(serviceAccount));
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.balanceOf.call(serviceAccount), "ether"));
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount), "ether"));
        assert.equal(etherAmount * 2 * await dao.rate.call(), web3.fromWei(await token.totalSupply.call(), "ether"));
    });

    it("Should deposit ether with commission and mint tokens", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        const commission = Commission.at(await dao.commissionContract.call());
        await commission.sendTransaction({from: unknownAccount, value: weiAmount});

        const token = Token.at(await dao.token.call());
        assert.equal(weiAmount, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(weiAmount, await dao.depositedWithCommission.call(unknownAccount));
        assert.equal(weiAmount, await dao.commissionRaised.call());
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount), "ether"));
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.totalSupply.call(), "ether"));
    });

    it("Should deposit ether with commission and mint tokens for 2 accounts", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        const commission = Commission.at(await dao.commissionContract.call());
        await Promise.all([
            commission.sendTransaction({from: unknownAccount, value: weiAmount}),
            commission.sendTransaction({from: serviceAccount, value: weiAmount})
        ]);

        const token = Token.at(await dao.token.call());
        assert.equal(weiAmount * 2, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(weiAmount, await dao.depositedWei.call(serviceAccount));
        assert.equal(weiAmount, await dao.depositedWithCommission.call(unknownAccount));
        assert.equal(weiAmount, await dao.depositedWithCommission.call(serviceAccount));
        assert.equal(weiAmount * 2, await dao.commissionRaised.call());
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount), "ether"));
        assert.equal(etherAmount * await dao.rate.call(), web3.fromWei(await token.balanceOf.call(serviceAccount), "ether"));
        assert.equal(etherAmount * 2 * await dao.rate.call(), web3.fromWei(await token.totalSupply.call(), "ether"));
    });

    it("Should not let send ether before crowdsale start", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        let callID = 0;

        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);
        await helper.rpcCall(web3, "evm_increaseTime", [50], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        await helper.handleErrorTransaction(() => dao.sendTransaction({from: unknownAccount, value: weiAmount}));
    });

    it("Should not let send more ether than hardCap", async () => {
        const etherAmount = 20.1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        let callID = 0;

        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);
        await helper.rpcCall(web3, "evm_increaseTime", [70], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        await helper.handleErrorTransaction(() => dao.sendTransaction({from: accounts[2], value: weiAmount}));
    });

    it("Should not let send more ether after end of crowdsale", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        let callID = 0;

        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);
        await helper.rpcCall(web3, "evm_increaseTime", [130], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        await helper.handleErrorTransaction(() => dao.sendTransaction({from: unknownAccount, value: weiAmount}));
    });

    it("Should finish crowdsale with achieved softCap", async () => {
        const etherAmount = 10.1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        let callID = 2;

        const holdTime = await helper.initBonuses(dao, accounts);
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);

        const commission = Commission.at(await dao.commissionContract.call());
        await dao.sendTransaction({from: accounts[2], value: weiAmount});
        await commission.sendTransaction({from: accounts[3], value: web3.toWei(1, "ether")});
        await helper.rpcCall(web3, "evm_increaseTime", [60], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        const token = Token.at(await dao.token.call());
        const [totalSupply, latestBlock] = await Promise.all([
            token.totalSupply.call(),
            helper.getLatestBlock(web3)
        ]);

        await dao.finish.sendTransaction({from: unknownAccount});

        assert.equal(true, await dao.crowdsaleFinished.call());
        assert.equal(false, await dao.refundableSoftCap.call());
        assert.equal(true, await token.mintingFinished.call());
        assert.equal(latestBlock.timestamp + holdTime, await token.held.call(serviceAccount));
        assert.equal(latestBlock.timestamp + holdTime, await token.held.call(unknownAccount));
        assert.equal(Math.round(web3.fromWei(totalSupply * 0.05)), web3.fromWei((await token.balanceOf.call(serviceAccount))));
        assert.equal(Math.round(web3.fromWei(totalSupply * 0.1)), web3.fromWei((await token.balanceOf.call(unknownAccount))));
        const serviceContract = await dao.serviceContract.call();
        const [serviceContractBalance, commissionRaised] = await Promise.all([
            helper.rpcCall(web3, "eth_getBalance", [serviceContract], callID++),
            dao.commissionRaised.call()
        ]);
        assert.equal(web3.fromWei((commissionRaised / 100) * 4), web3.fromWei(serviceContractBalance.result));
    });

    it("Should finish crowdsale without achieved softCap", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        let callID = 2;

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({from: accounts[2], value: weiAmount});
        await helper.rpcCall(web3, "evm_increaseTime", [60], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        const token = Token.at(await dao.token.call());
        await dao.finish.sendTransaction({from: unknownAccount});

        assert.equal(true, await dao.crowdsaleFinished.call());
        assert.equal(true, await dao.refundableSoftCap.call());
        assert.equal(true, await token.mintingFinished.call());
    });

    it("Should not let finish crowdsale before it's end", async () => {
        let callID = 2;

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await helper.rpcCall(web3, "evm_increaseTime", [50], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        await helper.handleErrorTransaction(async () => await dao.finish.sendTransaction({from: unknownAccount}));
    });

    it("Should not let finish crowdsale twice", async () => {
        let callID = 2;

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await helper.rpcCall(web3, "evm_increaseTime", [60], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        await dao.finish.sendTransaction({from: unknownAccount});
        await helper.handleErrorTransaction(async () => await dao.finish.sendTransaction({from: unknownAccount}));
    });
});