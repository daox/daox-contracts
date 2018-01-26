// const Promise = require('bluebird');
// const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");
// const Users = artifacts.require("./Users/Users.sol");
// const DAOx = artifacts.require("./DAOx.sol");
// const Common = artifacts.require("./Common.sol");
// const Voting = artifacts.require("./Voting/Voting.sol");
// Voting.link(Common);
// const VotingFactory = artifacts.require("./Voting/VotingFactory.sol");
// const DAO = artifacts.require("./DAO/DAO.sol");
// const Token = artifacts.require("./Token/Token.sol");
// const DAOJson = require('../../build/contracts/DAO.json');
// const Web3 = require("web3");
// const web3 = new Web3();
//
// module.exports = {
//     createCrowdsaleDAOFactory: (accounts, data = null) => {
//         data = data || ["Test Token", "TTK", "Base", "Base DAO", 51, accounts[1]];
//         const [tokenName, tokenSymbol, daoName, daoDescription, minVote, DAOOwner1] = data;
//         let voting, cdf, votingFactory, token, users, baseDAO, daoX;
//
//         return Voting.new().then(_voting => {
//             voting = _voting;
//
//             return Promise.all([VotingFactory.new(voting.address), Token.new(tokenName, tokenSymbol), Users.new(), DAOx.new()]);
//         }).then(([_votingFactory, _token, _users, _daoX]) => {
//             votingFactory = _votingFactory;
//             token = _token;
//             users = _users;
//             daoX = _daoX;
//
//             return DAO.new(DAOOwner1, token.address, votingFactory.address, users.address, daoName, daoDescription, minVote);
//         }).then(_baseDAO => {
//             baseDAO = _baseDAO;
//             return CrowdsaleDAOFactory.new(users.address, daoX.address, votingFactory.address, baseDAO.address);
//         }).then(_cdf => {
//             cdf = _cdf;
//             cdf.users = users;
//             cdf.votingFactory = votingFactory;
//             cdf.token = token;
//             cdf.daox = daoX;
//
//             return cdf;
//         });
//     },
//
//     createCrowdsaleDAO: (cdf, accounts, data = null) => {
//         const [daoName, daoDescription, daoMinVote, DAOOwner, softCap, hardCap, rate, startBlock, endBlock] = data || ["Test", "Test DAO", 51, accounts[2], 100, 1000, 100, 100, 100000];
//
//         return cdf.createCrowdsaleDAO(daoName, daoDescription, daoMinVote, DAOOwner, cdf.token.address, softCap, hardCap, rate, startBlock, endBlock)
//             .then(tx => {
//                 const result = web3.eth.abi.decodeParameters(["address", "string"], tx.receipt.logs[0].data);
//                 cdf.dao = new web3.eth.Contract(DAOJson.abi, result[0]);
//
//                 return cdf;
//             });
//     }
//
//
// };

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