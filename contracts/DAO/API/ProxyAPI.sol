pragma solidity 0.4.24;

import "./TypesConverter.sol";

interface IDaoAPI {
    function apiSettersModule() view returns(address);

    function handleAPICall(string signature, bytes32 value) external;
}

interface IAllowedSetters {
    function signatures(bytes32 method) view returns(bytes32);
}

contract ProxyAPI {
    mapping(address => address) public availableCalls;

    function callService(address _address, bytes32 method, bytes32[10] args) external {
        availableCalls[_address] = msg.sender;
        string memory signature = getServiceSignature(method);
        require(_address.call(bytes4(keccak256(signature)), args), "Service call ended with error");
        availableCalls[_address] = 0x0;
    }

    function callDAOSetter(bytes32 method, bytes32 value) external {
        require(availableCalls[msg.sender] != 0x0, "Setter is not available for this address");
        string memory signature = getDAOSetterSignature(availableCalls[msg.sender], method);
        IDaoAPI(availableCalls[msg.sender]).handleAPICall(signature, value);
    }

    function getServiceSignature(bytes32 method) private view returns(string){
        bytes memory concatenatedBytes = abi.encodePacked(TypesConverter.bytes32ToString(method), "(bytes32[10])");
        return string(concatenatedBytes);
    }

    function getDAOSetterSignature(address dao, bytes32 method) private view returns(string) {
        string memory signature = TypesConverter.bytes32ToString(IAllowedSetters(IDaoAPI(dao).apiSettersModule()).signatures(method));
        require(keccak256(signature) != keccak256(""), "No such setter");

        return signature;
    }
}
