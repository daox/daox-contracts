const DAOLib = artifacts.require("./DAO/DAOLib.sol");
const helper = require("../helpers/helper");

contract("DAOLib", accounts => {
    let instance = null;
    let startTime = null;
    const timeShift = 10000;
    const multiplier = 1e6;

    before(async () => instance = await DAOLib.deployed());
    beforeEach(async () => {
        const block = await helper.getLatestBlock(web3);
        startTime = block.timestamp;
    });

    it("Count tokens without bonuses", async () => {
        const etherAmount = 0.3;
        const rate = 1000;

        const tokensAmount = await instance.countTokens.call(web3.toWei(etherAmount, "ether"), [], [], rate);

        assert.equal(etherAmount * rate, web3.fromWei(tokensAmount, "ether"));
    });

    // it("Count tokens with bonuses", async () => {
    //     const etherAmount = 1;
    //     const rate = 1000;
    //     const bonusRates = [rate + 500, rate + 300, rate + 200];
    //
    //     const tokensAmountWithBonus1 = await instance.countTokens.call(web3.toWei(etherAmount, "ether"),
    //         [startTime + timeShift, startTime + 2 * timeShift, startTime + 3 * timeShift], bonusRates, rate);
    //
    //     await helper.rpcCall(web3, "evm_increaseTime", [timeShift]);
    //     await helper.rpcCall(web3, "evm_mine", null);
    //
    //     const tokensAmountWithBonus2 = await instance.countTokens.call(web3.toWei(etherAmount, "ether"),
    //         [startTime + timeShift, startTime + 2 * timeShift, startTime + 3 * timeShift], bonusRates, rate);
    //
    //     await helper.rpcCall(web3, "evm_increaseTime", [timeShift]);
    //     await helper.rpcCall(web3, "evm_mine", null);
    //
    //     const tokensAmountWithBonus3 = await instance.countTokens.call(web3.toWei(etherAmount, "ether"),
    //         [startTime + timeShift, startTime + 2 * timeShift, startTime + 3 * timeShift], bonusRates, rate);
    //     await helper.rpcCall(web3, "evm_increaseTime", [timeShift]);
    //     await helper.rpcCall(web3, "evm_mine", null);
    //
    //     const tokensAmountWithoutBonus = await instance.countTokens.call(web3.toWei(etherAmount, "ether"),
    //         [startTime + timeShift, startTime + 2 * timeShift, startTime + 3 * timeShift], bonusRates, rate);
    //
    //     assert.equal(etherAmount * bonusRates[0], (web3.fromWei(tokensAmountWithBonus1, "ether")).toNumber());
    //     assert.equal(etherAmount * bonusRates[1], (web3.fromWei(tokensAmountWithBonus2, "ether")).toNumber());
    //     assert.equal(etherAmount * bonusRates[2], (web3.fromWei(tokensAmountWithBonus3, "ether").toNumber()));
    //     assert.equal(etherAmount * rate, (web3.fromWei(tokensAmountWithoutBonus, "ether")).toNumber());
    // });

    // it("Count refund sum when newRate = rate", async () => {
    //     const rate = 10;
    //     const newRate = 10;
    //     const weiSpent = web3.toWei(2.1, "ether");
    //
    //     const weiAmount = await instance.countRefundSum(weiSpent, rate, newRate * multiplier);
    //
    //     assert.equal(weiSpent, weiAmount.toNumber(), "Error when newRate = rate");
    // });
    //
    // it("Count refund sum when newRate = 0.5 rate", async () => {
    //     const rate = 10;
    //     const newRate = 5;
    //     const weiSpent = web3.toWei(1.1, "ether");
    //
    //     const weiAmount = await instance.countRefundSum(rate, newRate, weiSpent);
    //
    //     assert.equal(weiSpent * newRate / rate, weiAmount.toNumber(), "Error when newRate = 0.5 rate");
    // });
    //
    // it("Count refund sum when newRate = 0.7 rate", async () => {
    //     const rate = 50;
    //     const newRate = 35;
    //     const weiSpent = web3.toWei(0.3, "ether");
    //
    //     const weiAmount = await instance.countRefundSum(rate, newRate, weiSpent);
    //
    //     assert.equal(weiSpent * newRate / rate, weiAmount.toNumber(), "Error when newRate = 0.7 rate");
    // });
    //
    // it("Count refund sum when newRate = 0.11 rate", async () => {
    //     const rate = 100;
    //     const newRate = 11;
    //     const weiSpent = web3.toWei(1.667, "ether");
    //
    //     const weiAmount = await instance.countRefundSum(rate, newRate, weiSpent);
    //
    //     assert.equal(weiSpent * newRate / rate, weiAmount.toNumber(), "Error when newRate = 0.11 rate");
    // });
});



