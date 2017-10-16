pragma solidity ^0.4.11;

contract Users {
    mapping(address => User) public users;

    struct User {
        bytes32 name;
        bytes32 secondName;
        bytes32 email;
    }

    function registerNewUser(string name, string secondName, string email, address userAddress) {
        users[userAddress] = User(sha256(name), sha256(secondName), sha256(email));
    }

    function isExist(address userAddress) public constant returns(bool) {
        return users[userAddress].name != 0x0;
    }
}