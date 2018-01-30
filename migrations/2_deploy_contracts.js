const Common = artifacts.require("./Common.sol");
const Token = artifacts.require("./Token/Token.sol");
const VotingFactory = artifacts.require("./Votings/VotingFactory.sol");
const VotingLib = artifacts.require("./Votings/VotingLib.sol");
const DAOx = artifacts.require("./DAOx.sol");
const DAOLib = artifacts.require("./DAO/DAOLib.sol");
const CrowdsaleDAOFactory = artifacts.require("./DAO/CrowdsaleDAOFactory.sol");
const State = artifacts.require("./DAO/Modules/State.sol");
const Payment = artifacts.require("./DAO/Modules/Payment.sol");
const VotingDecisions = artifacts.require("./DAO/Modules/VotingDecisions.sol");
const Crowdsale = artifacts.require("./DAO/Modules/Crowdsale.sol");
const Voting = artifacts.require("./DAO/Votings/Voting.sol");
const DAODeployer = artifacts.require("./DAO/DAODeployer.sol");
const DAOProxy = artifacts.require("./DAO/DAOProxy.sol");

module.exports = (deployer) => {
    const deployVotingFactory = () =>
        deployer.deploy(Common)
            .then(() => deployer.link(Common, Voting) && deployer.deploy(Voting) && deployer.deploy(VotingLib))
            .then(() => deployer.link(VotingLib, VotingFactory) && deployer.deploy(VotingFactory, Voting.address));

    const deployDAOx = () =>
        deployer.deploy(DAOx);

    const deployModules = () =>
        deployer.deploy(DAOLib)
            .then(() => deployer.deploy(State))
            .then(() => deployer.link(DAOLib, [Payment, Crowdsale]) && deployer.deploy(Payment))
            .then(() => deployer.deploy(VotingDecisions))
            .then(() => deployer.deploy(Crowdsale));

    const deployCrowdsaleDAOFactory = () =>
        deployer.link(Common, [CrowdsaleDAOFactory, DAODeployer]) && deployer.deploy(DAOProxy)
            .then(() => deployer.link(DAOLib, DAODeployer) && deployer.link(DAOProxy, DAODeployer) && deployer.deploy(DAODeployer))
            .then(() => deployer.link(DAODeployer, CrowdsaleDAOFactory))
            .then(() => deployer.deploy(CrowdsaleDAOFactory, DAOx.address, VotingFactory.address, [State.address, Payment.address, VotingDecisions.address, Crowdsale.address]));

    return Promise.all([deployVotingFactory(), deployDAOx(), deployModules()])
        .then(() => deployCrowdsaleDAOFactory())
};

