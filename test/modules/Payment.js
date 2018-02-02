const Payment = artifacts.require("./DAO/Modules/Payment.sol");
const Commission = artifacts.require("./Commission.sol");
const DAOX = artifacts.require("./DAOx.sol");
const Token = artifacts.require("./Token/Token.sol");

const helper = require('../helpers/helper.js');

contract("Payment", accounts => {
    const serviceAccount = accounts[0];
    const unknownAccount = accounts[1];

    const [daoName, daoDescription, tokenName, tokenSymbol] = ["DAO NAME", "THIS IS A DESCRIPTION", "TEST TOKEN", "TTK"];
    let softCap, hardCap, rate, startTime, endTime;
    let cdf, dao, crowdsaleParameters;
    const shiftTime1 = 10000;
    const shiftTime2 = 20000;
    let callID = 0;

    before(async () => cdf = await helper.createCrowdsaleDAOFactory(accounts));

    beforeEach(async () => {
        dao = await helper.createCrowdsaleDAO(cdf, accounts, [daoName, daoDescription]);

        const block = await helper.getLatestBlock(web3);

        [softCap, hardCap, rate, startTime, endTime] = [3, 10, 5000, block.timestamp + shiftTime1, block.timestamp + shiftTime2];
        crowdsaleParameters = [softCap, hardCap, rate, startTime, endTime];

        //Initialize transaction
        await Promise.all([
            helper.initState(cdf, dao, serviceAccount),
            helper.initCrowdsaleParameters(dao, serviceAccount, web3, crowdsaleParameters)
        ]);

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime1], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);
    });

    it("Should send commission tokens", async () => {
        const commissionContractAddress = await dao.commissionContract.call();
        const commissionContract = Commission.at(commissionContractAddress);

        await commissionContract.sendTransaction({
            from: unknownAccount,
            value: web3.toWei(softCap, "ether")
        });

        assert.equal(web3.toWei(softCap, "ether"), await dao.commissionRaised.call(), "Commission raised variable is not correct");
        assert.equal(web3.toWei(softCap, "ether"), await dao.depositedWithCommission.call(unknownAccount), "Deposited with commission was not calculated correct");

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime2], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        await dao.finish.sendTransaction({
            from: unknownAccount
        });

        await dao.getCommissionTokens.sendTransaction({
            from: unknownAccount
        });

        const daox = DAOX.at(await dao.serviceContract.call());
        const daoXToken = Token.at(await daox.token.call());
        const balance = await daoXToken.balanceOf.call(unknownAccount);

        assert.equal(web3.toWei(softCap, "ether") * 100, balance, "Received invalid amount of DAOx tokens");
    });

    it("Should refund when soft cap was not reached", async () => {
        await dao.sendTransaction({
            from: accounts[2],
            value: web3.toWei(softCap / 2, "ether"),
            gasPrice: 0
        });

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime2], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

        await dao.finish.sendTransaction({
            from: accounts[2],
            gasPrice: 0
        });

        assert.isTrue(await dao.crowdsaleFinished.call(), "Crowdsale was not finished");
        assert.isTrue(await dao.refundableSoftCap.call(), "Crowdsale is not refundable");
        assert.isNotTrue(await dao.weiRaised.call() > await dao.softCap.call(), "Wei raised should be less than soft cap");
        assert.equal(web3.toWei(softCap / 2), (await dao.weiRaised.call()).toNumber(), "Wei raised calculated not correct");

        let rpcResponse = await helper.rpcCall(web3, "eth_getBalance", [accounts[2]], callID++);
        const balanceBefore = web3.fromWei(rpcResponse.result);

        await dao.refundSoftCap.sendTransaction({
            from: accounts[2],
            gasPrice: 0
        });

        rpcResponse = await helper.rpcCall(web3, "eth_getBalance", [accounts[2]], callID++);
        const balanceAfter = web3.fromWei(rpcResponse.result);

        assert.equal(parseFloat(balanceBefore) + softCap / 2, parseInt(balanceAfter), "Refunded amount of ether is not correct");
    });

    it("Should not refund when soft cap was reached", async () => {
        await dao.sendTransaction({
            from: accounts[2],
            value: web3.toWei(softCap, "ether"),
            gasPrice: 0
        });

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime2], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

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

        await helper.rpcCall(web3, "evm_increaseTime", [shiftTime2], callID++);
        await helper.rpcCall(web3, "evm_mine", null, callID++);

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