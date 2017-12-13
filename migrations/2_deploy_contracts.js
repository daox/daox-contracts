const Common = artifacts.require("./Common.sol");
const Users = artifacts.require("./Users/Users.sol");
const Token = artifacts.require("./Token/Token.sol");
const VotingFactory = artifacts.require("./Votings/VotingFactory.sol");
const VotingLib = artifacts.require("./Votings/VotingLib.sol");
const DAOx = artifacts.require("./DAOx.sol");
const DAO = artifacts.require("./DAO/DAO.sol");
const DAOLib = artifacts.require("./DAO/DAOLib.sol");
const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");

module.exports = function (deployer) {
    Promise.all([
        deployer.deploy(Common),
        deployer.deploy(VotingLib),
        deployer.deploy(DAOLib)
    ]).then(() => Promise.all([
        deployer.link(Common, [VotingFactory, Users, CrowdsaleDAOFactory]),
        deployer.link(VotingLib, VotingFactory),
        deployer.link(DAOLib, CrowdsaleDAOFactory),
    ])).then(() => Promise.all([
        deployer.deploy(Users),
        deployer.deploy(Token),
        deployer.deploy(VotingFactory),
        deployer.deploy(DAOx),
        deployer.deploy(DAO)
    ])).then(() => deployer.deploy(CrowdsaleDAOFactory, Users.address, DAOx.address, VotingFactory.address, DAO.address));
};
