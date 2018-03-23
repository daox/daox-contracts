const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");
const CrowdsaleDAO = artifacts.require("./DAO/CrowdsaleDAO.sol");
const DAOx = artifacts.require("./DAOx.sol");
const Common = artifacts.require("./Common.sol");
const Voting = artifacts.require("./Votings/Voting.sol");
const VotingFactory = artifacts.require("./Votings/VotingFactory.sol");
const Token = artifacts.require("./Token/Token.sol");
const DAOProxy = artifacts.require("./DAO/DAOProxy.sol");
const DAOLib = artifacts.require("./DAO/DAOLib.sol");
const State = artifacts.require("./DAO/Modules/State.sol");
const Payment = artifacts.require("./DAO/Modules/Payment.sol");
const VotingDecisions = artifacts.require("./DAO/Modules/VotingDecisions.sol");
const Crowdsale = artifacts.require("./DAO/Modules/Crowdsale.sol");
CrowdsaleDAOFactory.link(DAOProxy);
CrowdsaleDAOFactory.link(DAOLib);
const DAOJson = require("../../build/contracts/CrowdsaleDAO");
const DXT = artifacts.require("./Token/DXT.sol");
const Web3 = require("web3");
const web3 = new Web3();

const createCrowdsaleDAOFactory = async () => {
    const _DAOx = await DAOx.new();
    const _VotingFactory = await VotingFactory.new(Voting.address);

    return CrowdsaleDAOFactory.new(
        _DAOx.address,
        _VotingFactory.address,
        [State.address, Payment.address, VotingDecisions.address, Crowdsale.address]
    );
};

const createCrowdsaleDAO = async (cdf, accounts, data = null) => {
    const [daoName, daoDescription] = data || ["Test", "Test DAO"];

    const tx = await cdf.createCrowdsaleDAO(daoName, daoDescription);
    const logs = web3.eth.abi.decodeParameters(["address", "string"], tx.receipt.logs[0].data);

    return CrowdsaleDAO.at(logs[0]);
};

const initCrowdsaleParameters = async (dao, account, _web3, dxtPayments = true, data = null) => {
    const latestBlock = await getLatestBlock(_web3);
    const [softCap, hardCap, etherRate, DXTRate, startTime, endTime] = data || [10, 20, 1000, 500, latestBlock.timestamp + 60, latestBlock.timestamp + 120];

    await dao.initCrowdsaleParameters.sendTransaction(softCap, hardCap, etherRate, DXTRate, startTime, endTime, dxtPayments, {
        from: account,
        gasPrice: 0
    });

    return [softCap, hardCap, etherRate, DXTRate, startTime, endTime];
};

const createToken = (tokenName, tokenSymbol) => Token.new(tokenName, tokenSymbol);

const getLatestBlock = _web3 =>
    new Promise((resolve, reject) =>
        _web3.eth.getBlock("latest", (err, block) => err ? reject(err) : resolve(block)));

let callID = 0;
const rpcCall = (_web3, methodName, params) =>
    new Promise((resolve, reject) => {
        _web3.currentProvider.sendAsync({
            jsonrpc: "2.0",
            method: methodName,
            params: params,
            id: callID++
        }, (err, result) => {
            if (err) return reject(err);

            resolve(result);
        });
    });

const fillZeros = (phrase) => {
    const totalLength = 66;
    const lengthDifference = totalLength - phrase.length;
    const zeroArray = new Array(lengthDifference).fill(0);

    return phrase.concat(zeroArray.join(""));
};

const handleErrorTransaction = async (transaction) => {
    let error;

    try {
        await transaction();
    } catch (e) {
        error = e;
    } finally {
        assert.isDefined(error, "Revert was not thrown out");
    }
};

const getParametersForInitState = (cdf, tokenName, tokenSymbol) =>
    Promise.all([
        cdf.serviceContractAddress.call(),
        cdf.votingFactoryContractAddress.call(),
        createToken(tokenName, tokenSymbol),
    ]);

const initState = async (cdf, dao, account, tokenName = "TEST TOKEN", tokenSymbol = "TTK") => {
    const [daoxAddress, votingFactoryAddress, token] = await getParametersForInitState(cdf, tokenName, tokenSymbol);
    await dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, DXT.address, {from: account});
    await token.transferOwnership.sendTransaction(dao.address, {from: account});

    return Promise.resolve([daoxAddress, votingFactoryAddress, token]);
};

const startCrowdsale = async (_web3, cdf, dao, serviceAccount, dxtPayments = true) => {
    const [, crowdsaleParams] = await Promise.all([
        initState(cdf, dao, serviceAccount),
        initCrowdsaleParameters(dao, serviceAccount, _web3, dxtPayments)
    ]);
    await rpcCall(_web3, "evm_increaseTime", [60]);
    await rpcCall(_web3, "evm_mine", null);

    return crowdsaleParams;
};

const initBonuses = async (dao, accounts, _web3) => {
    const block = await getLatestBlock(_web3);
    const date = block.timestamp;
    const holdTime = 60 * 60 * 24;
    await dao.initBonuses([accounts[0], accounts[1]], [5, 10], [date, date + 60], [10, 20], [100, 200], [holdTime, holdTime], [false, false]);

    return [date, holdTime];
};

const makeCrowdsale = async (_web3, cdf, dao, accounts, successful = true) => {
    const etherAmount = successful ? 10.1 : 0.1;
    const weiAmount = _web3.toWei(etherAmount, "ether");

    await startCrowdsale(_web3, cdf, dao, accounts[0]);
    await Promise.all([
        dao.sendTransaction({from: accounts[0], value: weiAmount}),
        dao.sendTransaction({from: accounts[1], value: _web3.toWei(1, "ether")})
    ]);

    await rpcCall(_web3, "evm_increaseTime", [60]);
    await rpcCall(_web3, "evm_mine", null);

    return dao.finish();
};

const makeCrowdsaleNew = async (_web3, cdf, dao, serviceAccount, backers, shiftTime = 60) => {
    await startCrowdsale(_web3, cdf, dao, serviceAccount);
    await Promise.all(Object.keys(backers).map(address => dao.sendTransaction({
        from: address,
        value: backers[address]
    })));
    await rpcCall(_web3, "evm_increaseTime", [shiftTime]);
    await rpcCall(_web3, "evm_mine", null);

    return dao.finish();
};

const decodeVotingParameters = (tx) =>
    web3.eth.abi.decodeParameters(["address", "string", "address", "bytes32", "uint", "address"], tx.receipt.logs[0].data);

const finishVoting = async (shiftTime, finish, duration, voting, _web3) => {
    if (shiftTime) {
        await rpcCall(_web3, "evm_increaseTime", [duration]);
        await rpcCall(_web3, "evm_mine", null);
    }
    if (finish) {
        return voting.finish()
    }
};

const makeWithdrawal = async (backersToOptions, finish = true, shiftTime = false, withdrawal, duration, _web3) => {
    await Promise.all(Object.keys(backersToOptions).map(key => withdrawal.addVote.sendTransaction(backersToOptions[key], {from: key})));

    return finishVoting(shiftTime, finish, duration, withdrawal, _web3);
};

const makeModule = async (backersToOptions, finish = true, shiftTime = false, module, duration, _web3) => {
    await Promise.all(Object.keys(backersToOptions).map(key => module.addVote.sendTransaction(backersToOptions[key], {from: key})));

    return finishVoting(shiftTime, finish, duration, module, _web3);
};

const makeProposal = async (backersToOptions, finish = true, shiftTime = false, proposal, duration, _web3) => {
    await Promise.all(Object.keys(backersToOptions).map(key => proposal.addVote.sendTransaction(backersToOptions[key], {from: key})));

    return finishVoting(shiftTime, finish, duration, proposal, _web3);
};

const makeRefund = async (backersToOptions, finish, shiftTime, refund, duration, _web3) => {
    await Promise.all(Object.keys(backersToOptions).map(key => refund.addVote.sendTransaction(backersToOptions[key], {from: key})));

    return finishVoting(shiftTime, finish, duration, refund, _web3);
};

const getBalance = async (_web3, address, convertToWei = true) => {
    const rpcResponse = await rpcCall(_web3, "eth_getBalance", [address]);

    return convertToWei ? _web3.fromWei(rpcResponse.result) : rpcResponse.result;
};

const mintDXT = async (to, amount = 1) => {
    const token = DXT.at(DXT.address);
    await token.mint(to, amount);

    return token;
};

const EPSILON = 1e-9;
const doesApproximatelyEqual = (a, b) =>
    a + EPSILON >= b && a - EPSILON <= b;


module.exports = {
    getLatestBlock, rpcCall, fillZeros, makeCrowdsale,
    handleErrorTransaction, createCrowdsaleDAOFactory,
    createCrowdsaleDAO, decodeVotingParameters, mintDXT,
    initCrowdsaleParameters, initState, initBonuses, startCrowdsale, makeCrowdsaleNew,
    makeWithdrawal, makeModule, makeProposal, makeRefund, getBalance, doesApproximatelyEqual
};