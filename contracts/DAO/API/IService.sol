pragma solidity ^0.4.0;

interface IService {
    function priceToConnect() public view returns(uint);

    function priceToCall() public view returns(uint);

    function calledWithVoting(bytes32 method) public view returns(bool);
}
