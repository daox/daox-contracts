pragma solidity 0.4.24;

import '../../../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import "../DAOLib.sol";
import "../../Token/TokenInterface.sol";
import "../CrowdsaleDAOFields.sol";
import "../API/IService.sol";

interface IProxyAPI {
    function callService(address _address, bytes32 method, bytes32[10] _bytes) external;
}

contract VotingDecisions is CrowdsaleDAOFields {

    /*
    * @dev Transfers withdrawal sum in ether or DXC tokens to the whitelisted address. Calls from Withdrawal proposal
    * @param _address Whitelisted address
    * @param _withdrawalSum Amount of ether/DXC to be sent
    * @param _dxc Should withdrawal be in DXC tokens
    */
    function withdrawal(address _address, uint _withdrawalSum, bool _dxc) external notInRefundableState onlyVoting {
        lastWithdrawalTimestamp = block.timestamp;
        _dxc ? DXC.transfer(_address, _withdrawalSum) : _address.transfer(_withdrawalSum);
    }

    /*
    * @dev Change DAO's mode to `refundable`. Can be called by any tokenholder
    */
    function makeRefundableByUser() external {
        require(lastWithdrawalTimestamp == 0 && block.timestamp >= created_at + withdrawalPeriod
        || lastWithdrawalTimestamp != 0 && block.timestamp >= lastWithdrawalTimestamp + withdrawalPeriod);
        makeRefundable();
    }

    /*
    * @dev Change DAO's mode to `refundable`. Calls from Refund proposal
    */
    function makeRefundableByVotingDecision() external onlyVoting {
        makeRefundable();
    }

    /*
    * @dev Change DAO's mode to `refundable`. Calls from this contract `makeRefundableByUser` or `makeRefundableByVotingDecision` functions
    */
    function makeRefundable() private notInRefundableState {
        refundable = true;
        newEtherRate = SafeMath.mul(this.balance * etherRate, multiplier) / tokensMintedByEther;
        newDXCRate = tokensMintedByDXC != 0 ? SafeMath.mul((DXC.balanceOf(this) - initialCapital) * DXCRate, multiplier) / tokensMintedByDXC : 0;
    }

    /*
    * @dev Make tokens of passed address non-transferable for passed period
    * @param _address Address of tokenholder
    * @param _duration Hold's duration in seconds
    */
    function holdTokens(address _address, uint _duration) external onlyVoting {
        token.hold(_address, _duration);
    }

    function connectService(address _service) external validServiceCaller(_service, "connect") validInitialCapital(_service, "connect") {
        payForService(_service, "connect");
        services[_service] = true;
    }

    function callService(address _service, bytes32 _method, bytes32[10] _args) external validServiceCaller(_service, _method) validInitialCapital(_service, "call") {
        payForService(_service, "call");
        IProxyAPI(proxyAPI).callService(_service, _method, _args);
    }

    function payForService(address _service, string action) private {
        uint price = keccak256(action) == keccak256("call") ? IService(_service).priceToCall() : IService(_service).priceToConnect();
        initialCapital -= price;
        DXC.contributeTo(_service, price);
    }

    /*
    * @dev Throws if called not by any voting contract
    */
    modifier onlyVoting() {
        require(votings[msg.sender] != 0x0);
        _;
    }

    /*
    * @dev Throws if DAO is in refundable state
    */
    modifier notInRefundableState {
        require(!refundable && !refundableSoftCap);
        _;
    }

    modifier validInitialCapital(address _service, string action) {
        uint price = keccak256(action) == keccak256("call") ? IService(_service).priceToCall() : IService(_service).priceToConnect();
        require(price <= initialCapital, "Not enough funds to use module");
        _;
    }

    modifier validServiceCaller(address _service, bytes32 _method) {
        bool votingNeeded = canInitCrowdsaleParameters && _method == bytes32("connect") ? false : IService(_service).calledWithVoting(_method);
        require(votingNeeded ? (votings[msg.sender] != 0x0) : true, "Method can be called only via voting");
        _;
    }
}
