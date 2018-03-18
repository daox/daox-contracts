"use strict";
const helper = require('../helpers/helper.js');
const Token = artifacts.require("./Token/Token.sol");
const Commission = artifacts.require("./Commission.sol");
const DXT = artifacts.require("./Token/DXT.sol");

contract("Crowdsale", accounts => {
    const [serviceAccount, unknownAccount] = [accounts[0], accounts[1]];

    let cdf, dao;

    before(async () => cdf = await helper.createCrowdsaleDAOFactory());
    beforeEach(async () => dao = await helper.createCrowdsaleDAO(cdf));

    it("Should set parameters for crowdsale", async () => {
        const [softCap, hardCap, etherRate, DXTRate, startTime, endTime] = await helper.initCrowdsaleParameters(dao, serviceAccount, web3);

        const [contractSF, contractHC] = await Promise.all([dao.softCap.call(), dao.hardCap.call()]);
        assert.equal(web3.toWei(softCap), contractSF.toString());
        assert.equal(web3.toWei(hardCap), contractHC.toString());
        assert.equal(etherRate, await dao.etherRate.call());
        assert.equal(DXTRate, await dao.DXTRate.call());
        assert.equal(startTime, await dao.startTime.call());
        assert.equal(endTime, await dao.endTime.call());
    });

    it("Should not be able to set parameters for crowdsale from unknown account", () =>
        helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, unknownAccount, web3))
    );

    it("Should not be able to set parameters for crowdsale when start time already passed", async () => {
        const latestBlock = await helper.getLatestBlock(web3);
        const data = [100, 200, 1000, 5000, latestBlock.timestamp - 1, latestBlock.timestamp + 120];

        return helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, serviceAccount, web3, true, data));
    });

    it("Should not be able to set parameters for crowdsale twice", async () => {
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);

        return helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, serviceAccount, web3));
    });

    it("Should not be able to set parameters for crowdsale when softCap > hardCap", async () => {
        const latestBlock = await helper.getLatestBlock(web3);
        const data = [200, 100, 1000, 5000, latestBlock.timestamp + 60, latestBlock.timestamp + 120];

        return helper.handleErrorTransaction(() => helper.initCrowdsaleParameters(dao, serviceAccount, web3, true, data));
    });

    it("Should deposit ether and mint tokens", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount);

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({from: unknownAccount, value: weiAmount});

        const token = Token.at(await dao.token.call());
        assert.equal(weiAmount, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount)));
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.totalSupply.call()));
    });

    it("Should deposit DXT and mint tokens", async () => {
        const DXTAmount = web3.toWei(1);
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await helper.mintDXT(unknownAccount, DXTAmount);
        const dxt = DXT.at(DXT.address);
        await dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: unknownAccount});

        const token = Token.at(await dao.token.call());
        assert.equal(DXTAmount, await dao.DXTRaised.call());
        assert.equal(DXTAmount, await dao.depositedDXT.call(unknownAccount));
        assert.equal(DXTAmount * await dao.DXTRate.call(),await token.balanceOf.call(unknownAccount));
        assert.equal(DXTAmount * await dao.DXTRate.call(), await dao.tokenMintedByDXT.call());
        assert.equal(DXTAmount * await dao.DXTRate.call(), await token.totalSupply.call());
        assert.equal(DXTAmount, await dxt.balanceOf.call(dao.address));
        assert.equal(0, await dxt.balanceOf.call(unknownAccount));
    });

    it("Should deposit DXT/ether and mint tokens", async () => {
        const DXTAmount = web3.toWei(1);
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount);
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        const dxt = await helper.mintDXT(unknownAccount, DXTAmount);
        await Promise.all([
            dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: unknownAccount}),
            dao.sendTransaction({from: unknownAccount, value: weiAmount})
        ]);

        const token = Token.at(await dao.token.call());

        const fundsRaised = parseInt(etherAmount * await dao.etherRate.call()) + parseInt(web3.fromWei(DXTAmount * await dao.DXTRate.call()));
        assert.equal(weiAmount, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(fundsRaised, web3.fromWei(await token.balanceOf.call(unknownAccount)));
        assert.equal(fundsRaised, web3.fromWei(await token.totalSupply.call()));
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await dao.tokenMintedByEther.call()));
        assert.equal(DXTAmount, await dao.DXTRaised.call());
        assert.equal(DXTAmount, await dao.depositedDXT.call(unknownAccount));
        assert.equal(DXTAmount * await dao.DXTRate.call(), await dao.tokenMintedByDXT.call());
        assert.equal(DXTAmount, await dxt.balanceOf.call(dao.address));
        assert.equal(0, await dxt.balanceOf.call(unknownAccount));
    });

    it("Should deposit ether and mint tokens for 2 accounts", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount);

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await Promise.all([
            dao.sendTransaction({from: unknownAccount, value: weiAmount}),
            dao.sendTransaction({from: serviceAccount, value: weiAmount})
        ]);

        const token = Token.at(await dao.token.call());
        assert.equal(weiAmount * 2, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(weiAmount, await dao.depositedWei.call(serviceAccount));
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.balanceOf.call(serviceAccount)));
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount)));
        assert.equal(etherAmount * 2 * await dao.etherRate.call(), web3.fromWei(await token.totalSupply.call()));
    });

    it("Should deposit ether with commission and mint tokens", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount);

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        const commission = Commission.at(await dao.commissionContract.call());
        await commission.sendTransaction({from: unknownAccount, value: weiAmount});

        const token = Token.at(await dao.token.call());
        assert.equal(weiAmount, await dao.weiRaised.call());
        assert.equal(weiAmount, await dao.depositedWei.call(unknownAccount));
        assert.equal(weiAmount, await dao.depositedWithCommission.call(unknownAccount));
        assert.equal(weiAmount, await dao.commissionRaised.call());
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount)));
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.totalSupply.call()));
    });

    it("Should deposit ether with commission and mint tokens for 2 accounts", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount);

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
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.balanceOf.call(unknownAccount)));
        assert.equal(etherAmount * await dao.etherRate.call(), web3.fromWei(await token.balanceOf.call(serviceAccount)));
        assert.equal(etherAmount * 2 * await dao.etherRate.call(), web3.fromWei(await token.totalSupply.call()));
    });

    it("Should not let send ether before crowdsale start", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount);

        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);
        await helper.rpcCall(web3, "evm_increaseTime", [50]);
        await helper.rpcCall(web3, "evm_mine", null);

        return helper.handleErrorTransaction(() => dao.sendTransaction({from: unknownAccount, value: weiAmount}));
    });

    it("Should not let send DXT before crowdsale start", async () => {
        const DXTAmount = 1;
        const dxt = await helper.mintDXT(unknownAccount, DXTAmount);

        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);
        await helper.rpcCall(web3, "evm_increaseTime", [50]);
        await helper.rpcCall(web3, "evm_mine", null);

        return helper.handleErrorTransaction(() => dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: unknownAccount}));
    });

    it("Should not let send more ether than hardCap", async () => {
        const DXTAmount = web3.toWei(38);
        const dxt = await helper.mintDXT(unknownAccount, DXTAmount);
        const etherAmount = 2;
        const weiAmount = web3.toWei(etherAmount);

        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);
        await helper.rpcCall(web3, "evm_increaseTime", [70]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.sendTransaction({from: accounts[2], value: weiAmount / 2});
        await dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: unknownAccount});

        return helper.handleErrorTransaction(() => dao.sendTransaction({from: accounts[2], value: weiAmount / 2}));
    });

    it("Should not let send more DXT than hardCap", async () => {
        const etherAmount = 19;
        const weiAmount = web3.toWei(etherAmount);
        const DXTAmount = web3.toWei(4);
        const dxt = await helper.mintDXT(unknownAccount, DXTAmount);

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({from: accounts[2], value: weiAmount});
        await dxt.contributeTo.sendTransaction(dao.address, DXTAmount/2, {from: unknownAccount});

        return helper.handleErrorTransaction(() => dxt.contributeTo.sendTransaction(dao.address, DXTAmount/2, {from: unknownAccount}));
    });

    it("Should not let send ether after the end of crowdsale", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount);

        await helper.initState(cdf, dao, serviceAccount);
        await helper.initCrowdsaleParameters(dao, serviceAccount, web3);
        await helper.rpcCall(web3, "evm_increaseTime", [130]);
        await helper.rpcCall(web3, "evm_mine", null);

        return helper.handleErrorTransaction(() => dao.sendTransaction({from: unknownAccount, value: weiAmount}));
    });

    it("Should not let send DXT after the end of crowdsale", async () => {
        const DXTAmount = 1;
        const dxt = await helper.mintDXT(unknownAccount, DXTAmount);

        await helper.makeCrowdsale(web3, cdf, dao, accounts, false);

        return helper.handleErrorTransaction(() => dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: unknownAccount}));
    });

    it("Should finish crowdsale with achieved softCap", async () => {
        const etherAmount = 10.1;
        const weiAmount = web3.toWei(etherAmount);

        const [, holdTime] = await helper.initBonuses(dao, accounts, web3);
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);

        const commission = Commission.at(await dao.commissionContract.call());
        await dao.sendTransaction({from: accounts[2], value: weiAmount});
        await commission.sendTransaction({from: accounts[3], value: web3.toWei(1)});
        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        const token = Token.at(await dao.token.call());
        const totalSupply = await token.totalSupply.call();

        await dao.finish.sendTransaction({from: unknownAccount});
        const latestBlock = await helper.getLatestBlock(web3);

        assert.equal(true, await dao.crowdsaleFinished.call());
        assert.equal(false, await dao.refundableSoftCap.call());
        assert.equal(true, await token.mintingFinished.call());
        assert.equal(latestBlock.timestamp + holdTime, (await token.held.call(serviceAccount)).toNumber());
        assert.equal(latestBlock.timestamp + holdTime, (await token.held.call(unknownAccount)).toNumber());
        assert.equal(Math.round(web3.fromWei(totalSupply * 0.05)), web3.fromWei((await token.balanceOf.call(serviceAccount))));
        assert.equal(Math.round(web3.fromWei(totalSupply * 0.1)), web3.fromWei((await token.balanceOf.call(unknownAccount))));
        const serviceContract = await dao.serviceContract.call();
        const [serviceContractBalance, commissionRaised] = await Promise.all([
            helper.rpcCall(web3, "eth_getBalance", [serviceContract]),
            dao.commissionRaised.call()
        ]);
        assert.equal(web3.fromWei((commissionRaised / 100) * 4), web3.fromWei(serviceContractBalance.result));
    });

    it("Should finish crowdsale with softCap which was achieved via DXT", async () => {
        const DXTAmount = web3.toWei(21);
        const dxt = await helper.mintDXT(accounts[2], DXTAmount);

        const [, holdTime] = await helper.initBonuses(dao, accounts, web3);
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);

        await dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: accounts[2]});
        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        const token = Token.at(await dao.token.call());
        const totalSupply = await token.totalSupply.call();

        await dao.finish.sendTransaction({from: unknownAccount});
        const latestBlock = await helper.getLatestBlock(web3);

        assert.equal(true, await dao.crowdsaleFinished.call());
        assert.equal(false, await dao.refundableSoftCap.call());
        assert.equal(true, await token.mintingFinished.call());
        assert.equal(DXTAmount, await dxt.balanceOf.call(dao.address));
        assert.equal(latestBlock.timestamp + holdTime, (await token.held.call(serviceAccount)).toNumber());
        assert.equal(latestBlock.timestamp + holdTime, (await token.held.call(unknownAccount)).toNumber());
        assert.equal(Math.round(web3.fromWei(totalSupply * 0.05)), web3.fromWei((await token.balanceOf.call(serviceAccount))));
        assert.equal(Math.round(web3.fromWei(totalSupply * 0.1)), web3.fromWei((await token.balanceOf.call(unknownAccount))));
    });

    it("Should finish crowdsale without achieved softCap", async () => {
        const etherAmount = 1;
        const weiAmount = web3.toWei(etherAmount, "ether");

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({from: accounts[2], value: weiAmount});
        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        const token = Token.at(await dao.token.call());
        await dao.finish.sendTransaction({from: unknownAccount});

        assert.equal(true, await dao.crowdsaleFinished.call());
        assert.equal(true, await dao.refundableSoftCap.call());
        assert.equal(true, await token.mintingFinished.call());
    });

    it("Should finish crowdsale invested by DXT without achieved softCap", async () => {
        const DXTAmount = 19;
        const dxt = await helper.mintDXT(accounts[2], DXTAmount);

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: accounts[2]});
        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        const token = Token.at(await dao.token.call());
        await dao.finish.sendTransaction({from: unknownAccount});

        assert.equal(true, await dao.crowdsaleFinished.call());
        assert.equal(true, await dao.refundableSoftCap.call());
        assert.equal(true, await token.mintingFinished.call());
    });

    it("Should finish crowdsale with achieved hardCap before it's end", async () => {
        const etherAmount = 20;
        const weiAmount = web3.toWei(etherAmount, "ether");

        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({from: accounts[2], value: weiAmount});
        await helper.rpcCall(web3, "evm_increaseTime", [30]);
        await helper.rpcCall(web3, "evm_mine", null);

        const token = Token.at(await dao.token.call());
        await dao.finish.sendTransaction({from: unknownAccount});

        assert.equal(true, await dao.crowdsaleFinished.call());
        assert.equal(false, await dao.refundableSoftCap.call());
        assert.equal(true, await token.mintingFinished.call());
        assert.deepEqual(await dao.hardCap.call(), await dao.weiRaised.call());
    });

    it("Should not let finish crowdsale before it's end", async () => {
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await helper.rpcCall(web3, "evm_increaseTime", [50]);
        await helper.rpcCall(web3, "evm_mine", null);

        return helper.handleErrorTransaction(() => dao.finish.sendTransaction({from: unknownAccount}));
    });

    it("Should not let finish crowdsale twice", async () => {
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await helper.rpcCall(web3, "evm_increaseTime", [60]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.finish.sendTransaction({from: unknownAccount});

        return helper.handleErrorTransaction(() => dao.finish.sendTransaction({from: unknownAccount}));
    });

    it("Should not let invest with DXT when dxt payments are off", async () => {
        const DXTAmount = 19;
        const dxt = await helper.mintDXT(accounts[2], DXTAmount);
        await helper.startCrowdsale(web3, cdf, dao, serviceAccount, false);

        return helper.handleErrorTransaction(() => dxt.contributeTo.sendTransaction(dao.address, DXTAmount, {from: accounts[2]}));
    });
});