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

    it("Token's maximum supply can't be exceeded", async () => {
        await dxc.mint(accounts[1], web3.toWei(THREE_HUNDRED_MILLION - 2), {from: accounts[3]}); // maximum supply has reached

        assert.deepEqual(await dxc.totalSupply(), await dxc.maximumSupply());

        return helper.handleErrorTransaction(() => dxc.mint(accounts[1], web3.toWei(1), {from: accounts[3]}));
    });
});