pragma solidity ^0.4.0;

import "./DAOFactoryInterface.sol";
import "./DAODeployer.sol";
import "../Common.sol";
import "../Token/TokenInterface.sol";

contract CrowdsaleDAOFactory is DAOFactoryInterface {
    event CrowdsaleDAOCreated(
        address _address,
        string _name
    );

    address public serviceContractAddress;
    address public votingFactoryContractAddress;
    address public DXC;
    mapping(address => uint) DXCDeposit;
    // DAOs created by factory
    mapping(address => string) DAOs;
    // Functional modules which will be used by DAOs to delegate calls
    address[4] modules;

    function CrowdsaleDAOFactory(address _serviceContractAddress, address _votingFactoryAddress, address _DXC, address[4] _modules) {
        require(_serviceContractAddress != 0x0 && _votingFactoryAddress != 0x0 && _DXC != 0x0);
        serviceContractAddress = _serviceContractAddress;
        DXC = _DXC;
        votingFactoryContractAddress = _votingFactoryAddress;
        modules = _modules;

        require(votingFactoryContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
        require(serviceContractAddress.call(bytes4(keccak256("setDaoFactory(address)")), this));
    }

    /*
    * @dev Checks if provided address is an address of some DAO contract created by this factory
    * @param _address Address of contract
    * @return boolean indicating whether the contract was created by this factory or not
    */
    function exists(address _address) external constant returns (bool) {
        return keccak256(DAOs[_address]) != keccak256("");
    }

    /*
    * @dev Receives info about address which sent DXC tokens to current contract and about amount of sent tokens from
    *       DXC token contract and then saves this information to DXCDeposit mapping
    * @param _from Address which sent DXC tokens
    * @param _amount Amount of tokens which were sent
    */
    function handleDXCPayment(address _from, uint _dxcAmount) external onlyDXC {
        require(_dxcAmount >= 10**18, "Amount of DXC for initial deposit must be equal or greater than 1 DXC");

        DXCDeposit[_from] += _dxcAmount;
    }

    /*
    * @dev Creates new CrowdsaleDAO contract, provides it with addresses of modules, transfers ownership to tx sender
    *      and saves address of created contract to DAOs mapping
    * @param _name Name of the DAO
    * @param _name Description for the DAO
    * @param _initialCapital initial capital for DAO that will be created
    */
    function createCrowdsaleDAO(string _name, string _description, uint _initialCapital) public correctInitialCapital(_initialCapital) enoughDXC(_initialCapital) {
        address dao = DAODeployer.deployCrowdsaleDAO(_name, _description, serviceContractAddress, votingFactoryContractAddress, DXC, _initialCapital);
        DXCDeposit[msg.sender] -= _initialCapital;
        TokenInterface(DXC).transfer(dao, _initialCapital);

        require(dao.call(bytes4(keccak256("setStateModule(address)")), modules[0]));
        require(dao.call(bytes4(keccak256("setPaymentModule(address)")), modules[1]));
        require(dao.call(bytes4(keccak256("setVotingDecisionModule(address)")), modules[2]));
        require(dao.call(bytes4(keccak256("setCrowdsaleModule(address)")), modules[3]));
        DAODeployer.transferOwnership(dao, msg.sender);

        DAOs[dao] = _name;
        CrowdsaleDAOCreated(dao, _name);
    }

    modifier onlyDXC() {
        require(msg.sender == address(DXC), "Method can be called only from DXC contract");
        _;
    }

    modifier correctInitialCapital(uint value) {
        require(value >= 10**18, "Initial capital should be equal at least 1 DXC");
        _;
    }

    modifier enoughDXC(uint value) {
        require(value <= TokenInterface(DXC).balanceOf(this), "Not enough DXC tokens were transferred for such initial capital");
        require(DXCDeposit[msg.sender] >= value, "Not enough DXC were transferred by your address");
        _;
    }
}