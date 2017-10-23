pragma solidity ^0.4.11;

contract Users {
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

    function registerNewUser(string name, string secondName, string email, address userAddress) {
        require(!doesExist(userAddress));
        User storage user = users[userAddress];
        user.name = sha256(name);
        user.secondName = sha256(secondName);
        user.email = sha256(email);
    }

    function doesExist(address userAddress) public constant returns(bool) {
        return users[userAddress].name != 0x0;
    }

    function approve(address _address, bytes32[] _properties) {
        require(doesExist(_address));
        User storage user = users[_address];
        //ToDo: replace require by if (???)
        for(uint i = 0; i < _properties.length; i++) {
            require(properties[_properties[i]]);
            user.approves[_properties[i]].push(msg.sender);
        }
    }

    function getApproves(address _address, bytes32 property) public constant returns(address[]) {
        require(doesExist(_address));
        User storage user = users[_address];

        return user.approves[property];
    }
}