const Promise = require('bluebird');
const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");
const Users = artifacts.require("./Users/Users.sol");
const DAOx = artifacts.require("./DAOx.sol");
const Common = artifacts.require("./Common.sol");
const Voting = artifacts.require("./Voting/Voting.sol");
Voting.link(Common);
const VotingFactory = artifacts.require("./Voting/VotingFactory.sol");
const Token = artifacts.require("./Token/Token.sol");
const State = artifacts.require("./DAO/Modules/State.sol");
const Payment = artifacts.require("./DAO/Modules/Payment.sol");
const VotingDecisions = artifacts.require("./DAO/Modules/VotingDecisions.sol");
const Crowdsale = artifacts.require("./DAO/Modules/Crowdsale.sol");
const Deployer = artifacts.require("./DAO/DAODeployer.sol");
const DAOLib = artifacts.require("./DAO/DAOLib.sol");
// const DAOProxy = artifacts.require("./DAO/DAOProxy.sol");
const Library = artifacts.require("./DAO/DAOProxy.sol");
const Web3 = require("web3");
const web3 = new Web3();

module.exports = {
    createCrowdsaleDAOFactory: (accounts, data = null) => {
        data = data || ["Test Token", "TTK", "Base", "Base DAO", 51, accounts[1]];
        const [tokenName, tokenSymbol, daoName, daoDescription, minVote, DAOOwner1] = data;
        let voting, cdf, votingFactory, token, users, baseDAO, daoX;

        return Voting.new().then(_voting => {
            voting = _voting;

            // return Promise.all([DAOLib.new(), DAOProxy.new()]);
            return Library.new();
        }).then((lib) => {
            console.log(lib.address);
            console.log(Library.isDeployed());
            Deployer.link(Library);
            // console.log(DAOProxy.isDeployed());
            // console.log(DAOLib.isDeployed());

            return Promise.all([VotingFactory.new(voting.address), Token.new(tokenName, tokenSymbol), DAOx.new(), DAODeployer.new()]);
        }).then(([_votingFactory, _token, _daoX]) => {
            votingFactory = _votingFactory;
            token = _token;
            daoX = _daoX;

            return Promise.all([State.new(), Payment.new(), VotingDecisions.new(), Crowdsale.new()]);
        }).then(([state, payment, votingDecisions, crowdsale]) =>
            CrowdsaleDAOFactory.new(daoX.address, votingFactory.address, [state.address, payment.address, votingDecisions.address, crowdsale.address])
        ).then(_cdf => {
            cdf = _cdf;
            cdf.votingFactory = votingFactory;
            cdf.daox = daoX;

            return cdf;
        });
    },

    // createCrowdsaleDAO: (cdf, accounts, data = null) => {
    //     const [daoName, daoDescription, daoMinVote, DAOOwner, softCap, hardCap, rate, startBlock, endBlock] = data || ["Test", "Test DAO", 51, accounts[2], 100, 1000, 100, 100, 100000];
    //
    //     return cdf.createCrowdsaleDAO(daoName, daoDescription, daoMinVote, DAOOwner, cdf.token.address, softCap, hardCap, rate, startBlock, endBlock)
    //         .then(tx => {
    //             const result = web3.eth.abi.decodeParameters(["address", "string"], tx.receipt.logs[0].data);
    //             cdf.dao = new web3.eth.Contract(DAOJson.abi, result[0]);
    //
    //             return cdf;
    //         });
    // }
};

const getLatestBlockTimestamp = web3 =>
    new Promise((resolve, reject) =>
        web3.eth.getBlock("latest", block => resolve(block)));

const rpcCall = (methodName, params, id) =>
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

module.exports.getLatestBlockTimestamp = getLatestBlockTimestamp;
module.exports.rpcCall = rpcCall;
module.exports.fillZeros = fillZeros;