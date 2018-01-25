const DAOLib = artifacts.require("./DAO/DAOLib.sol");
const [getLatestBlockTimestamp, rpcCall] = [require("./helpers/helper").getLatestBlockTimestamp, require("./helpers/helper").rpcCall];

contract("DAOLib", accounts => {
    let instance = null;
    let startTime = Math.floor(Date.now() / 1000);
    const timeShift = 10000;

    before(async () => {
        instance = await DAOLib.deployed();
    });

    it("Count tokens without bonuses", async () => {
        const etherAmount = 0.3;
        const rate = 1000;

        const tokensAmount = await instance.countTokens(web3.toWei(etherAmount, "ether"), [], [], rate);

        assert.equal(etherAmount * rate, web3.fromWei(tokensAmount, "ether"));
    });

    it("Count tokens with bonuses", async () => {
        const etherAmount = 0.75;
        const rate = 1000;
        const bonusRate = rate + 600;

        const tokensAmountWithBonus = await instance.countTokens(web3.toWei(etherAmount, "ether"), [startTime + timeShift], [bonusRate], rate);
        await rpcCall("evm_increaseTime", [2 * timeShift], 1);
        await rpcCall("evm_mine", null, 2);
        const tokensAmountWithoutBonus = await instance.countTokens(web3.toWei(etherAmount, "ether"), [startTime + timeShift], [bonusRate], rate);

        assert.equal(etherAmount * bonusRate, web3.fromWei(tokensAmountWithBonus, "ether"));
        assert.equal(etherAmount * rate, web3.fromWei(tokensAmountWithoutBonus, "ether"));
    });
});



