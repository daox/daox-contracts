"use strict";
const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");
const Users = artifacts.require("./Users/Users.sol");
const DAOx = artifacts.require("./DAOx.sol");
const Common = artifacts.require("./Common.sol");
const Voting = artifacts.require("./Voting/Voting.sol");
Voting.link(Common);
const VotingFactory = artifacts.require("./Voting/VotingFactory.sol");
const DAO = artifacts.require("./DAO/DAO.sol");
const Token = artifacts.require("./Token/Token.sol");

contract("CrowdsaleDAOFactory", accounts => {
    const [tokenName, tokenSymbol, daoName, daoDescription, minVote, DAOOwner1] = ["Test Token", "TTK", "Base", "Base DAO", 51, accounts[1]];
    let voting, cdf, votingFactory, token, users, baseDAO, daoX;

    beforeEach(() =>
        Voting.new().then(_voting => {
            voting = _voting;

            return Promise.all([VotingFactory.new(voting.address), Token.new(tokenName, tokenSymbol), Users.new(), DAOx.new()]);
        }).then(([_votingFactory, _token, _users, _daoX]) => {
            votingFactory = _votingFactory;
            token = _token;
            users = _users;
            daoX = _daoX;

            return DAO.new(DAOOwner1, token.address, votingFactory.address, users.address, daoName, daoDescription, minVote);
        }).then(_baseDAO => {
            baseDAO = _baseDAO;
console.log(users.address, daoX.address, votingFactory.address, baseDAO.address);
            return CrowdsaleDAOFactory.new(users.address, daoX.address, votingFactory.address, baseDAO.address);
        }).then(_cdf => cdf = _cdf));

    it("Unknown dao should not be in Factory", () => {
        return cdf.exists.call(accounts[0])
            .then(doesExist => assert.equal(false, doesExist, "Unknown DAO exists in User contract"))
        // .catch(err => assert.isDefined(err))
    });
});