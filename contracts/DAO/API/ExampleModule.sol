pragma solidity 0.4.24;

import "./TypesConverter.sol";

interface IProxyAPI {
    function availableCalls(address _this) constant returns(address);
    function callDAOSetter(bytes32 method, bytes32 value) external;
}

interface IDAO {
    function votingPrice() view returns (uint);
}

contract ExampleModule {
    address public proxyAPI;

    constructor(address _proxyAPI) {
        proxyAPI = _proxyAPI;
    }

    function changeVotingPrice(bytes32[10] args) onlyProxyAPI {
        uint multiplier = TypesConverter.bytes32ToUint(args[0]);
        uint newVotingPrice = IDAO(IProxyAPI(msg.sender).availableCalls(this)).votingPrice() * multiplier;
        IProxyAPI(msg.sender).callDAOSetter("setVotingPrice", TypesConverter.uintToBytes32(newVotingPrice));
    }

    modifier onlyProxyAPI() {
        require(msg.sender == proxyAPI, "Method can be call only from Daox API proxy contract");
        _;
    }
}
