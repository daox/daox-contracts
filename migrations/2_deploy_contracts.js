const Common = artifacts.require("./Common.sol");
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
const DXC = artifacts.require("./Token/DXC.sol");
const TypesConverter = artifacts.require("./DAO/API/TypesConverter.sol");
const ExampleModule = artifacts.require("./DAO/API/ExampleModule.sol");
const ProxyAPI = artifacts.require("./DAO/API/ProxyAPI.sol");
const AllowedSetters = artifacts.require("./DAO/API/AllowedSetters.sol");

module.exports = (deployer) => {
    const deployVotingFactory = () =>
        deployer.deploy(Common)
            .then(() => deployer.link(Common, Voting) && deployer.deploy(Voting))
            .then(() => deployer.link(Common, VotingLib) && deployer.deploy(VotingLib))
            .then(() => deployer.link(VotingLib, VotingFactory) && deployer.deploy(VotingFactory, Voting.address));

    const deployDAOx = () =>
        deployer.deploy(DAOx);

    const deployDXC = () =>
        deployer.deploy(DXC, "DAOX token", "DXC");

    const deployModules = () =>
        deployer.deploy(DAOLib)
            .then(() => deployer.deploy(State))
            .then(() => deployer.link(DAOLib, [Payment, Crowdsale]) && deployer.deploy(Payment))
            .then(() => deployer.deploy(VotingDecisions))
            .then(() => deployer.deploy(Crowdsale));

    const deployAPI = () =>
        deployer.deploy(TypesConverter)
            .then(() => deployer.link(TypesConverter, [AllowedSetters, ExampleModule, ProxyAPI]) && deployer.deploy(AllowedSetters))
            .then(() => deployer.deploy(ProxyAPI))
            .then(() => deployer.deploy(ExampleModule, ProxyAPI.address));

    const deployCrowdsaleDAOFactory = () =>
        deployer.deploy(DAOProxy)
            .then(() =>
                deployer.link(Common, [CrowdsaleDAOFactory, DAODeployer]) &&
                deployer.link(DAOLib, DAODeployer) &&
                deployer.link(DAOProxy, DAODeployer) &&
                deployer.deploy(DAODeployer)
            )
            .then(() => deployer.link(DAODeployer, CrowdsaleDAOFactory))
            .then(() => deployer.deploy(CrowdsaleDAOFactory, DAOx.address, VotingFactory.address, DXC.address,
                [State.address, Payment.address, VotingDecisions.address, Crowdsale.address, ProxyAPI.address, AllowedSetters.address]))
            .catch(console.error);

    /*
    Version with `Promise.all()` doesn't work properly
    */
    deployVotingFactory()
        .then(() => deployDXC())
        .then(() => deployDAOx())
        .then(() => deployModules())
        .then(() => deployAPI())
        .then(() => deployCrowdsaleDAOFactory());
};

