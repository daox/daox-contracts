const Payment = artifacts.require("./DAO/Modules/Payment.sol");
const helper = require('../helpers/helper.js');

contract("Payment", accounts => {
    const serviceAccount = accounts[0];
    const unknownAccount = accounts[1];

    const [daoName, daoDescription] = ["DAO NAME", "THIS IS A DESCRIPTION"];
    let softCap, hardCap, etherRate, DXCRate, startTime, endTime;
    let cdf, dao;
    const shiftTime = 20000;

    before(async () => cdf = await helper.createCrowdsaleDAOFactory(accounts));

    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription]);
    });

    it("Should refund when soft cap was not reached", async () => {
        [softCap, hardCap, etherRate, DXCRate, startTime, endTime] = await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        const DXCAmount = 5;
        const dxc = await helper.mintDXC(accounts[2], DXCAmount);
        await dao.sendTransaction({from: accounts[2], value: web3.toWei(softCap / 2), gasPrice: 0});
        await dxc.contributeTo.sendTransaction(dao.address, DXCAmount, {from: accounts[2], gasPrice: 0});

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.finish.sendTransaction({from: accounts[2], gasPrice: 0});

        const fundsRaised = (await dao.weiRaised.call()).toNumber() + web3.toWei(DXCAmount) / (etherRate / DXCRate);
        assert.isTrue(await dao.crowdsaleFinished.call(), "Crowdsale was not finished");
        assert.isTrue(await dao.refundableSoftCap.call(), "Crowdsale is not refundable");
        assert.isNotTrue(fundsRaised > (await dao.softCap.call()).toNumber(), "Funds raised should be less than soft cap");
        assert.equal(web3.toWei(softCap / 2), (await dao.weiRaised.call()).toNumber(), "Wei raised calculated not correct");
        assert.equal(DXCAmount, (await dao.DXCRaised.call()).toNumber(), "DXC raised calculated not correct");

        let rpcResponse = await helper.rpcCall(web3, "eth_getBalance", [accounts[2]]);
        const balanceBefore = web3.fromWei(rpcResponse.result);

        await dao.refundSoftCap.sendTransaction({from: accounts[2], gasPrice: 0});

        rpcResponse = await helper.rpcCall(web3, "eth_getBalance", [accounts[2]]);
        const balanceAfter = web3.fromWei(rpcResponse.result);

        assert.equal(parseFloat(balanceBefore) + softCap / 2, parseInt(balanceAfter), "Refunded amount of ether is not correct");
    });

    it("Should not refund when soft cap was reached", async () => {
        [softCap, hardCap, etherRate, DXCRate, startTime, endTime] = await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({
            from: accounts[2],
            value: web3.toWei(softCap, "ether"),
            gasPrice: 0
        });

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.finish.sendTransaction({
            from: accounts[2],
            gasPrice: 0
        });

        assert.isTrue(await dao.crowdsaleFinished.call(), "Crowdsale was not finished");
        assert.isTrue((await dao.weiRaised.call()).toNumber() === (await dao.softCap.call()).toNumber(), "Wei raised should be equal soft cap");
        assert.equal(web3.toWei(softCap), (await dao.weiRaised.call()).toNumber(), "Wei raised calculated not correct");

        return helper.handleErrorTransaction(() => dao.refundSoftCap.sendTransaction({
            from: accounts[2],
            gasPrice: 0
        }));
    });

    it("Should not refund to unknown account when soft cap was not reached", async () => {
        [softCap, hardCap, etherRate, DXCRate, startTime, endTime] = await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
        await dao.sendTransaction({
            from: accounts[2],
            value: web3.toWei(softCap / 2, "ether"),
            gasPrice: 0
        });

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.finish.sendTransaction({
            from: accounts[2],
            gasPrice: 0
        });

        assert.isTrue(await dao.crowdsaleFinished.call(), "Crowdsale was not finished");
        assert.isTrue(await dao.refundableSoftCap.call(), "Crowdsale is not refundable");
        assert.isNotTrue((await dao.weiRaised.call()).toNumber() >= (await dao.softCap.call()).toNumber(), "Wei raised should be equal soft cap");

        return helper.handleErrorTransaction(() => dao.refundSoftCap.sendTransaction({
            from: unknownAccount,
            gasPrice: 0
        }));
    });

    it("Should accept DXC for initial capital only when crowdsale is not ongoing", async () => {
        const initialCapital = await dao.initialCapital();
        const dxc = await helper.mintDXC(serviceAccount, 4);
        await dxc.contributeTo.sendTransaction(dao.address, 1);

        assert.deepEqual(web3.toBigNumber(1), await dao.initialCapitalIncr(serviceAccount));
        assert.deepEqual(initialCapital.plus(1), await dao.initialCapital());

        const [, crowdsaleParams] = await Promise.all([
            helper.initState(cdf, dao, serviceAccount),
            helper.initCrowdsaleParameters(dao, serviceAccount, web3, true, null, 0)
        ]);
        await helper.rpcCall(web3, "evm_increaseTime", [30]);
        await helper.rpcCall(web3, "evm_mine", null);
        [softCap, hardCap, etherRate, DXCRate, startTime, endTime] = crowdsaleParams;

        await dxc.contributeTo.sendTransaction(dao.address, 1);
        assert.deepEqual(web3.toBigNumber(2), await dao.initialCapitalIncr(serviceAccount));
        assert.deepEqual(initialCapital.plus(2), await dao.initialCapital());

        await helper.rpcCall(web3, "evm_increaseTime", [30]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dao.sendTransaction({
            from: accounts[2],
            value: web3.toWei(softCap, "ether"),
            gasPrice: 0
        });

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime]);
        await helper.rpcCall(web3, "evm_mine", null);

        await dxc.contributeTo.sendTransaction(dao.address, 1);
        assert.notDeepEqual(web3.toBigNumber(3), await dao.initialCapitalIncr(serviceAccount));
        assert.notDeepEqual(initialCapital.plus(3), await dao.initialCapital());

        await dao.finish.sendTransaction({
            from: accounts[2],
            gasPrice: 0
        });
        await dxc.contributeTo.sendTransaction(dao.address, 1);

        assert.deepEqual(web3.toBigNumber(3), await dao.initialCapitalIncr(serviceAccount));
        assert.deepEqual(initialCapital.plus(3), await dao.initialCapital());

    });
});