pragma solidity 0.4.24;

import "./IService.sol";

interface IDXC {
    function transfer(address to, uint256 value) public returns (bool);
}

contract BaseService {
    address public DXC;
    address public owner;
    address public proxyAPI;
    uint public price;
    mapping(address => bool) daos;

    constructor(uint _price, address _DXC, address _proxyAPI) public {
        owner = msg.sender;
        price = _price;
        DXC = _DXC;
        proxyAPI = _proxyAPI;
    }

    function handleDXCPayment(address _from, uint _amount) correctPayment(_amount) {
        daos[msg.sender] = true;
    }

    function withdrawDXC(uint _amount) onlyOwner {
        IDXC(DXC).transfer(msg.sender, _amount);
    }

    modifier correctPayment(uint _amount) {
        require(_amount == price, "Incorrect number of DXC was transferred");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Method can be called only by owner");
        _;
    }
}
