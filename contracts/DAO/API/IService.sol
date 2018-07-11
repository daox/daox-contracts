pragma solidity ^0.4.0;

interface IService {
    function price(bytes32 action) public view returns(uint);
    function priceToConnect() public view returns(uint);
    function priceToCall() public view returns(uint);
}
