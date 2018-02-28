pragma solidity ^0.4.0;

contract Owned {
    address public owner;

    function Owned(address _owner) {
        owner = _owner;
    }

    function transferOwnership(address newOwner) onlyOwner(msg.sender) {
        owner = newOwner;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }
}
