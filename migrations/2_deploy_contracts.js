const Common = artifacts.require("./Common.sol");
const Users = artifacts.require("./Users/Users.sol");
const Token = artifacts.require("./Token/Token.sol");
const VotingFactory = artifacts.require("./Votings/VotingFactory.sol");
const VotingLib = artifacts.require("./Votings/VotingLib.sol");
const DAOx = artifacts.require("./DAOx.sol");
const DAO = artifacts.require("./DAO/DAO.sol");
const DAOLib = artifacts.require("./DAO/DAOLib.sol");
const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");

module.exports = function(deployer) {
    deployer.deploy(Common);
    deployer.deploy(VotingLib);
    deployer.deploy(DAOLib);

    const arr = [deployer.link(Common, Users),
    deployer.deploy(Users),


    deployer.deploy(Token),

    deployer.link(Common, VotingFactory),
    deployer.link(VotingLib, VotingFactory),
    deployer.deploy(VotingFactory),

    deployer.deploy(DAOx),

    deployer.deploy(DAO),

    deployer.link(DAOLib, CrowdsaleDAOFactory)];

    Promise.all(arr).then( () => deployer.deploy(CrowdsaleDAOFactory, Users.address, DAOx.address, VotingFactory.address, DAO.address));
};
