pragma solidity 0.4.24;

import "./IService.sol";
import "./IProxyAPI.sol";

interface IDXC {
    function transfer(address to, uint256 value) public returns (bool);
}

contract BaseService {
    address public DXC;
    address public owner;
    address public proxyAPI;
    uint public priceToConnect;
    uint public priceToCall;
    mapping(address => bool) public daos;
    mapping(address => uint) public callDeposit;
    mapping(bytes32 => bool) public calledWithVoting;

    constructor(uint _priceToConnect, uint _priceToCall, address _DXC, address _proxyAPI) public {
        owner = msg.sender;
        priceToConnect = _priceToConnect;
        priceToCall = _priceToCall;
        DXC = _DXC;
        proxyAPI = _proxyAPI;
        calledWithVoting["connect"] = true;
    }

    function handleDXCPayment(address _from, uint _amount) correctPayment(_amount, daos[_from]) onlyDXC {
        if(!daos[_from]) daos[_from] = true;
        else callDeposit[_from] += _amount;
    }

    function withdrawDXC(uint _amount) onlyOwner {
        IDXC(DXC).transfer(msg.sender, _amount);
    }

    modifier correctPayment(uint _amount, bool _connected) {
        uint price = _connected ? priceToCall : priceToConnect;
        require(_amount == price, "Incorrect number of DXC was transferred");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Method can be called only by owner");
        _;
    }

    modifier onlyDXC {
        require(msg.sender == DXC, "Method can be called only by DXC contract");
        _;
    }

    modifier onlyProxyAPI() {
        require(msg.sender == proxyAPI, "Method can be call only from Daox API proxy contract");
        _;
    }

    modifier onlyConnected {
        address dao = IProxyAPI(msg.sender).availableCalls(this);
        require(daos[dao], "Service is not connected");
        _;
    }
    modifier canCall {
        address dao = IProxyAPI(msg.sender).availableCalls(this);
        require(callDeposit[dao] >= priceToCall, "Not enough funds deposited to make a call");
        _;
    }
}
