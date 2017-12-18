pragma solidity ^0.4.0;

contract Owned {
    address owner;

    function Owned(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner(msg.sender) {
        owner = newOwner;
    }
}
