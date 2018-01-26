const Common = artifacts.require("./Common.sol");
const fillZeros = require("../helpers/helper.js").fillZeros;

contract("Common", () => {
    let instance = null;

    before(async () => {
        instance = await Common.deployed();
    });

    it("String to bytes32 test#1", async () => {
        const string = "test";

        const bytes = await instance.stringToBytes32(string);

        assert.equal(fillZeros(web3.toHex(string)), bytes, `${string} in test#1 converted not correct`);
    });

    it("String to bytes32 test#2", async () => {
        const string = "16symbolsstring1"; // 16 symbols string = 32 bytes

        const bytes = await instance.stringToBytes32(string);

        assert.equal(fillZeros(web3.toHex(string)), bytes, `${string} in test#2 converted not correct`);
    });

    it("String to bytes32 test#3", async () => {
        const string = "16symbolsstring116symbolsstring1"; // 16 symbols string = 32 bytes

        const bytes = await instance.stringToBytes32(string);

        assert.equal(fillZeros(web3.toHex(string)), bytes, `${string} in test#3 converted not correct`);
    });

    it("Percent test with integers", async () => {
        const numerators = [0, 1, 2, 5, 16, 17, 20, 23, 25, 50, 75, 85, 99, 100];
        const denominator = 100;

        const results = await Promise.all(numerators.map(numerator => instance.percent(numerator, denominator, 2)));

        results.forEach((result, i) => assert.equal(numerators[i], result.toNumber(), `Percent with numerator = ${numerators[i]} and denominator = ${denominator} calculated not correct`));
    });

    it("Percent test with non-integers", async () => {
        const numerators = [0, 1, 2, 3, 4, 5, 10, 15, 20, 25, 50, 77, 88, 99, 100, 111, 123];
        const denominator = 123;

        const results = await Promise.all(numerators.map(numerator => instance.percent(numerator, denominator, 2)));

        results.forEach((result, i) => assert.equal(Math.round(numerators[i]/denominator * 100), result.toNumber(), `Percent with numerator = ${numerators[i]} and denominator = ${denominator} calculated not correct`));
    });
});