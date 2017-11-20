const Common = artifacts.require("./Common.sol");
const Users = artifacts.require("./Users/Users.sol");

module.exports = function(deployer) {
    deployer.deploy(Common);
    deployer.link(Common, Users);
    deployer.deploy(Users);
  // deployer.link(ConvertLib, MetaCoin);
  // deployer.deploy(MetaCoin);
};
