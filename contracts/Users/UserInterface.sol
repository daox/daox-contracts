pragma solidity ^0.4.11;

interface UserInterface {
    function doesExist(address userAddress) public constant returns(bool);
}
