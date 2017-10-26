pragma solidity ^0.4.11;

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
            require(properties[_properties[i]] != false);
            user.approves[_properties[i]].push(msg.sender);
        }
    }

    function getApproves(address _address, string property) public constant returns(address[]) {
        require(doesExist(_address));
        User storage user = users[_address];

        return user.approves[stringToBytes32(property)];
    }

    function stringToBytes32(string memory source) private returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }

        return result;
    }
}

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender != owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract DAO is Owned {
    /*
    Reference to external contract
    */
    Users public users;

    event ProposalCreated(uint proposalID);
    event OptionCreated(uint optionID);

    struct Option {
    address[] votes;
    bytes32 description;
    }

    struct Vote {
    bool inSupport;
    address voter;
    }

    struct Proposal {
    bytes32 description;
    bool proposalPassed;
    Option[] options;
    mapping (address => bool) voted;
    Option result;
    uint votesCount;
    uint duration; // UNIX
    uint created_at; // UNIX
    bool finished;
    }

    /*
    Public dao properties
    */
    mapping (address => bool) public participants;
    string public name;
    uint256 public created_at; // UNIX time
    string public description;
    uint8 public minVote; // in percents
    Proposal[] proposals;
    uint participantsCount;

    function DAO(address _address, string _name, string _description, uint8 _minVote, address[] _participants)
    Owned()
    {
        users = Users(_address);
        name = _name;
        created_at = block.timestamp;
        description = _description;
        minVote = _minVote;
        for(uint i =0; i<_participants.length; i++) {
            require(users.doesExist(_participants[i]));
            participants[_participants[i]] = true;
        }
    }

    function isParticipant(address participantAddress) constant returns (bool) {
        return participants[participantAddress];
    }

    function addParticipant(address participantAddress) onlyOwner returns (bool) {
        require(users.doesExist(participantAddress));
        participants[participantAddress] = true;
        participantsCount++;


        return participants[participantAddress];
    }

    function remove(address _participantAddress) onlyOwner {
        removeParticipant(_participantAddress);
    }

    function leave() {
        removeParticipant(msg.sender);
    }

    function removeParticipant(address _address) private {
        require(users.doesExist(_address));
        participants[_address] = false;
        participantsCount--;
    }

    function addProposal(string _description, uint _duration, bytes32[] _options) returns (uint) {
        require(_options.length >= 2);
        uint proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.description = stringToBytes32(_description);
        p.proposalPassed = false;
        p.created_at = block.timestamp;
        p.duration = _duration;

        for (uint i = 0; i < _options.length; i++) {
            Option storage option = p.options[i];
            option.description = _options[i];
            OptionCreated(i);
        }

        ProposalCreated(proposalID);
    }

    function addVote(uint proposalID, uint optionID, address _address) {
        require(proposalID < proposals.length && optionID < p.options.length);
        Proposal storage p = proposals[proposalID];
        require(!p.finished && !p.voted[msg.sender]);
        Option storage o = p.options[optionID];
        o.votes.push(_address);
        p.votesCount++;

    }

    function finishProposal(uint proposalID) returns (bool) {
        require(proposalID < proposals.length);
        Proposal storage p = proposals[proposalID];
        require(p.duration + p.created_at >= block.timestamp);
        p.finished = true;
        if(p.votesCount/participantsCount*100 < minVote) return;

        Option storage result = p.options[0];
        for(uint i = 0; i< p.options.length; i++) {
            if(result.votes.length < p.options[i].votes.length) result = p.options[i];
        }

        p.result = result;
    }

    function getProposalInfo(uint proposalID) public constant returns (bytes32) {
        return proposals[proposalID].description;
    }

    function getProposalOptions(uint proposalID) public constant returns(bytes32[]) {
        Option[] storage options = proposals[proposalID].options;
        bytes32[] memory optionDescriptions = new bytes32[](options.length);
        for(uint i = 0; i < options.length; i++) {
            optionDescriptions[i] = options[i].description;
        }

        return optionDescriptions;
    }

    function getProposals() public constant returns(bytes32[]) {
        bytes32[] memory _proposalDescriptions = new bytes32[](proposals.length);
        for(uint i = 0; i < proposals.length; i++) {
            _proposalDescriptions[i] = proposals[i].description;
        }

        return _proposalDescriptions;
    }

    modifier onlyParticipant {
        require(participants[msg.sender] == true);
        _;
    }

    function stringToBytes32(string memory source) private returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }
    }
}