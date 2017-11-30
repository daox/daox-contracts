pragma solidity ^0.4.11;

import "../Common.sol";
import "./UserInterface.sol";

contract Users is UserInterface {
    mapping(address => User) public users;
    mapping(bytes32 => bool) public properties;

    struct User {
        bytes32 name;
        bytes32 secondName;
        bytes32 email;
        mapping(bytes32 => address[]) approves;
    }

    function Users() {
        properties["name"] = true;
        properties["secondName"] = true;
        properties["email"] = true;
    }

    function registerNewUser(string _name, string _secondName, string _email, address _userAddress) {
        require(!doesExist(_userAddress));
        User storage user = users[_userAddress];
        user.name = sha256(_name);
        user.secondName = sha256(_secondName);
        user.email = sha256(_email);
    }

    function doesExist(address userAddress) public constant returns(bool) {
        return users[userAddress].name != 0x0;
    }

    function approve(address _address, bytes32[] _properties) {
        require(doesExist(_address));
        User storage user = users[_address];
        //ToDo: replace require by if (???)
        for(uint i = 0; i < _properties.length; i++) {
            require(properties[_properties[i]] != false);
            user.approves[_properties[i]].push(msg.sender);
        }
    }

    function getApproves(address _address, string property) public constant returns(address[]) {
        require(doesExist(_address));
        User storage user = users[_address];

        return user.approves[Common.stringToBytes32(property)];
    }
}