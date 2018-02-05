const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");
const CrowdsaleDAO = artifacts.require("./DAO/CrowdsaleDAO.sol");
const Users = artifacts.require("./Users/Users.sol");
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
const Web3 = require("web3");
const web3 = new Web3();

const createCrowdsaleDAOFactory = async () => {
    const _DAOx = await DAOx.new();
    const _VotingFactory = await VotingFactory.new(Voting.address);

    return await CrowdsaleDAOFactory.new(
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

const initCrowdsaleParameters = async (dao, account, _web3, data = null) => {
    const latestBlock = await getLatestBlock(_web3);
    const [softCap, hardCap, rate, startTime, endTime] = data || [10, 20, 1000, latestBlock.timestamp + 60, latestBlock.timestamp + 120];

    await dao.initCrowdsaleParameters.sendTransaction(softCap, hardCap, rate, startTime, endTime, {
        from: account
    });
};

const createToken = (tokenName, tokenSymbol) => Token.new(tokenName, tokenSymbol);

const getLatestBlock = web3 =>
    new Promise((resolve, reject) =>
        web3.eth.getBlock("latest", (err, block) => err ? reject(err) : resolve(block)));

const rpcCall = (web3, methodName, params, id) =>
    new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
            jsonrpc: "2.0",
            method: methodName,
            params: params,
            id: id
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
        createToken(tokenName, tokenSymbol)
    ]);

const initState = async (cdf, dao, account, tokenName = "TEST TOKEN", tokenSymbol = "TTK") => {
    const [daoxAddress, votingFactoryAddress, token] = await Promise.all([
        cdf.serviceContractAddress.call(),
        cdf.votingFactoryContractAddress.call(),
        createToken(tokenName, tokenSymbol)
    ]);

    await dao.initState.sendTransaction(token.address, votingFactoryAddress, daoxAddress, {from: account});
    await token.transferOwnership.sendTransaction(dao.address, {from: account})
};

const startCrowdsale = async (_web3, cdf, dao, serviceAccount) => {
    let callID = 0;

    await Promise.all([
        initState(cdf, dao, serviceAccount),
        initCrowdsaleParameters(dao, serviceAccount, _web3)
    ]);
    await rpcCall(_web3, "evm_increaseTime", [60], callID++);
    await rpcCall(_web3, "evm_mine", null, callID++);
};

const initBonuses = async (dao, accounts) => {
    //ToDo: Fix to block.timestamp
    const date = Math.round(Date.now() / 1000);
    const holdTime = 60 * 60 * 24;
    await dao.initBonuses.sendTransaction([accounts[0], accounts[1]], [5, 10], [date, date + 60], [10, 20], [holdTime, holdTime], {from: accounts[0]});

    return [date, holdTime];
};

const makeCrowdsale = async (_web3, cdf, dao, serviceAccount, successful = true) => {
    const etherAmount = successful ? 10.1 : 0.1;
    const weiAmount = _web3.toWei(etherAmount, "ether");

    let callID = 2;

    await startCrowdsale(_web3, cdf, dao, serviceAccount);
    await dao.sendTransaction({from: serviceAccount, value: weiAmount});

    await rpcCall(_web3, "evm_increaseTime", [60], callID++);
    await rpcCall(_web3, "evm_mine", null, callID++);

    return await dao.finish.sendTransaction({from: serviceAccount});
};

const decodeVotingParameters = (tx) =>
    web3.eth.abi.decodeParameters(["address", "string", "address", "bytes32", "uint", "address"], tx.receipt.logs[0].data);


module.exports = {
    getLatestBlock, rpcCall, fillZeros, makeCrowdsale,
    handleErrorTransaction, createCrowdsaleDAOFactory,
    createCrowdsaleDAO, getParametersForInitState, decodeVotingParameters,
    initCrowdsaleParameters, initState, initBonuses, startCrowdsale
};