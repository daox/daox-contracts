pragma solidity 0.4.24;

import "./TypesConverter.sol";
import "./BaseService.sol";
import "./IProxyAPI.sol";
import "./IDAO.sol";

contract ExampleService is BaseService {
    constructor(uint _priceToConnect, uint _priceToCall, address _DXC, address _proxyAPI) BaseService(_priceToConnect, _priceToCall, _DXC, _proxyAPI) {
        calledWithVoting["changeVotingPrice"] = true;
    }

    function changeVotingPrice(bytes32[10] args) onlyProxyAPI onlyConnected canCall {
        address dao = IProxyAPI(msg.sender).availableCalls(this);
        callDeposit[dao] -= priceToCall;
        uint multiplier = TypesConverter.bytes32ToUint(args[0]);
        uint newVotingPrice = IDAO(dao).votingPrice() * multiplier;
        IProxyAPI(msg.sender).callDAOSetter("setVotingPrice", TypesConverter.uintToBytes32(newVotingPrice));
    }

    function changeName(bytes32[10] args) onlyProxyAPI onlyConnected canCall {
        IProxyAPI(msg.sender).callDAOSetter("setName", args[0]);
    }
}
