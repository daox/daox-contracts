pragma solidity ^0.4.11;

contract OwnedFields {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}