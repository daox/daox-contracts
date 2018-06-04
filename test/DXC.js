"use strict";
const DXC = artifacts.require("./Token/DXC.sol");
const helper = require("./helpers/helper");
let dxc;

contract("DXC", accounts => {
    const THREE_HUNDRED_MILLION = 300000000;

    before(async () => dxc = await DXC.new());

    it("Owner should be defined correct", async () => {
        assert.equal(accounts[0], await dxc.owner());
    });

    it("Maximum supply should be defined correct", async () => {
        assert.deepEqual(web3.toBigNumber(web3.toWei(THREE_HUNDRED_MILLION)), await dxc.maximumSupply());
    });

    it("Owner should be able to mint tokens", async () => {
        await dxc.mint(accounts[1], web3.toWei(1)); //mint 1 token

        assert.deepEqual(web3.toBigNumber(web3.toWei(1)), await dxc.balanceOf(accounts[1]));
    });

    it("Not owner or additional owner couldn't call `transferTokens` function", () => {
        return helper.handleErrorTransaction(() => dxc.transferTokens([accounts[9]], [100]), {from: accounts[1]})
    });

    it("Unknown account should be not able to mint tokens", async () => {
        assert.isFalse(await dxc.additionalOwners(accounts[1]));

        helper.handleErrorTransaction(() => dxc.mint(accounts[1], web3.toWei(1), {from: accounts[1]}));
    });

    it("Owner should be able to set additional owners", async () => {
        await dxc.setAdditionalOwners([accounts[1], accounts[2], accounts[3]]);

        assert.equal(accounts[1], await dxc.additionalOwnersList(0));
        assert.equal(accounts[2], await dxc.additionalOwnersList(1));
        assert.equal(accounts[3], await dxc.additionalOwnersList(2));

        assert.isTrue(await dxc.additionalOwners(accounts[1]));
        assert.isTrue(await dxc.additionalOwners(accounts[2]));
        assert.isTrue(await dxc.additionalOwners(accounts[3]));
    });

    it("Additional owner should be able to mint tokens", async () => {
        await dxc.mint(accounts[1], web3.toWei(1), {from: accounts[2]});

        assert.deepEqual(web3.toBigNumber(web3.toWei(2)), await dxc.balanceOf(accounts[1]));
        assert.deepEqual(web3.toBigNumber(web3.toWei(2)), await dxc.totalSupply());
    });

    it("Additional owner should be able to call `transferTokens` function", async () => {
        const balanceBefore = await dxc.balanceOf(accounts[1]);
        await dxc.transferTokens([accounts[5], accounts[6], accounts[7], accounts[8], accounts[0]], [100, 200, 300, 400, 1000], {from: accounts[1]});

        assert.deepEqual(web3.toBigNumber(100), await dxc.balanceOf(accounts[5]));
        assert.deepEqual(web3.toBigNumber(200), await dxc.balanceOf(accounts[6]));
        assert.deepEqual(web3.toBigNumber(300), await dxc.balanceOf(accounts[7]));
        assert.deepEqual(web3.toBigNumber(400), await dxc.balanceOf(accounts[8]));
        assert.deepEqual(web3.toBigNumber(1000), await dxc.balanceOf(accounts[0]));

        assert.deepEqual(balanceBefore.minus(web3.toBigNumber(2000)), await dxc.balanceOf(accounts[1]));
    });

    it("Owner should be able to call `transferTokens` function", async () => {
        const balanceBefore = await dxc.balanceOf(accounts[0]);
        await dxc.transferTokens([accounts[5], accounts[6], accounts[7], accounts[8]], [250, 250, 250, 250], {from: accounts[0]});

        assert.deepEqual(web3.toBigNumber(350), await dxc.balanceOf(accounts[5]));
        assert.deepEqual(web3.toBigNumber(450), await dxc.balanceOf(accounts[6]));
        assert.deepEqual(web3.toBigNumber(550), await dxc.balanceOf(accounts[7]));
        assert.deepEqual(web3.toBigNumber(650), await dxc.balanceOf(accounts[8]));

        assert.deepEqual(web3.toBigNumber(0), await dxc.balanceOf(accounts[0]));
    });

    it("Should throw an exception when length of addresses array != length of uint array in `transferTokens` function", async () => {
        assert.isTrue((await dxc.balanceOf(accounts[1])).toNumber() > 0);
        assert.isTrue(await dxc.additionalOwners(accounts[1]));

        return helper.handleErrorTransaction(() => dxc.transferTokens([accounts[8]], [100, 200]), {from: accounts[1]});
    });

    it("Should throw when amount of sending tokens is greater then balance", async () => {
        await dxc.setAdditionalOwners([accounts[5]], {from: accounts[0]});
        assert.equal(await dxc.additionalOwnersList(0), accounts[5]);
        assert.deepEqual(await dxc.balanceOf(accounts[5]), web3.toBigNumber(350)); // 350*10^-18 tokens

        await helper.handleErrorTransaction(() => dxc.transferTokens([accounts[0], accounts[1]], [200, 200]));
        assert.deepEqual(await dxc.balanceOf(accounts[5]), web3.toBigNumber(350)); // 350*10^-18 tokens
    });

    it("Token's maximum supply can't be exceeded", async () => {
        await dxc.mint(accounts[1], web3.toWei(THREE_HUNDRED_MILLION - 2), {from: accounts[5]}); // maximum supply has reached

        assert.deepEqual(await dxc.totalSupply(), await dxc.maximumSupply());

        return helper.handleErrorTransaction(() => dxc.mint(accounts[1], web3.toWei(1), {from: accounts[5]}));
    });
});