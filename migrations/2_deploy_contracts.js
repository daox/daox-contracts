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

module.exports = async deployer => {
    const deployVotingFactory = async _ => {
        await deployer.deploy(Common);
        deployer.link(Common, Voting);
        await Promise.all([deployer.deploy(Voting), deployer.deploy(VotingLib)]);
        deployer.link(VotingLib, VotingFactory);
        await deployer.deploy(VotingFactory, Voting.address);
    };

    const deployDAOx = _ =>
        deployer.deploy(DAOx);

    const deployModules = async _ => {
        await deployer.deploy(DAOLib);
        deployer.link(DAOLib, [Payment, Crowdsale]);
        await Promise.all([
            deployer.deploy(State),
            deployer.deploy(Payment),
            deployer.deploy(VotingDecisions),
            deployer.deploy(Crowdsale)
        ]);
    };

    const deployCrowdsaleDAOFactory = async _ => {
        await deployer.deploy(DAOProxy);
        deployer.link(Common, [CrowdsaleDAOFactory, DAODeployer]) && deployer.link(DAOLib, DAODeployer) && deployer.link(DAOProxy, DAODeployer);
        await deployer.deploy(DAODeployer);
        deployer.link(DAODeployer, CrowdsaleDAOFactory);
        await deployer.deploy(CrowdsaleDAOFactory, DAOx.address, VotingFactory.address, [State.address, Payment.address, VotingDecisions.address, Crowdsale.address]);
    };

    await Promise.all([deployVotingFactory(), deployDAOx(), deployModules()]);
    await deployCrowdsaleDAOFactory();
};

