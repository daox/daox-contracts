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

        [softCap, hardCap, etherRate, DXCRate, startTime, endTime] = await helper.startCrowdsale(web3, cdf, dao, serviceAccount);
    });

    it("Should refund when soft cap was not reached", async () => {
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
});