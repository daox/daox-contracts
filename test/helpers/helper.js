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

module.exports = {
    createCrowdsaleDAOFactory: async () => {
        const _DAOx = await DAOx.new();
        const _VotingFactory = await VotingFactory.new(Voting.address);

        return await CrowdsaleDAOFactory.new(
            _DAOx.address,
            _VotingFactory.address,
            [State.address, Payment.address, VotingDecisions.address, Crowdsale.address]
        );
    },

    createCrowdsaleDAO: async (cdf, data = null) => {
        const [daoName, daoDescription] = data || ["Test", "Test DAO"];

        const tx = await cdf.createCrowdsaleDAO(daoName, daoDescription);
        const logs = web3.eth.abi.decodeParameters(["address", "string"], tx.receipt.logs[0].data);

        return CrowdsaleDAO.at(logs[0]);
    },

    createToken: async (tokenName, tokenSymbol) => await Token.new(tokenName, tokenSymbol),

    initCrowdsaleParameters: async (dao, account, _web3, data = null) => {
        const latestBlock = await getLatestBlock(_web3);
        const [softCap, hardCap, rate, startTime, endTime] = data || [100, 200, 1000, latestBlock.timestamp + 60, latestBlock.timestamp + 120];

        await dao.initCrowdsaleParameters.sendTransaction(softCap, hardCap, rate, startTime, endTime, {
            from: account
        });
    }
};

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

module.exports.getLatestBlock = getLatestBlock;
module.exports.rpcCall = rpcCall;
module.exports.fillZeros = fillZeros;
module.exports.handleErrorTransaction = handleErrorTransaction;