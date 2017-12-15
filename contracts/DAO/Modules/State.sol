pragma solidity ^0.4.0;

import "../../DAO/Owned.sol";

contract State is Owned {
    address usersAddress;
    uint minVote;
    address tokenAddress;
    address votingFactory;
    address serviceContract;
    uint startBlock;
    uint tokenHoldTime;

    function initState(uint8 _minVote, address _usersAddress, address _tokenAddress, address _votingFactory, address _serviceContract) onlyOwner {
        require(_usersAddress != 0x0 && _tokenAddress != 0x0 && _votingFactory != 0x0 && _serviceContract != 0x0);
        users = UserInterface(_usersAddress);
        token = TokenInterface(_tokenAddress);
        votingFactory = VotingFactoryInterface(_votingFactory);
        minVote = _minVote;
        participants[owner] = true;
        created_at = block.timestamp;

        serviceContract = _serviceContract;
        commissionContract = new Commission(this);
        parentAddress = _parentAddress;
    }

    function initHold(uint _tokenHoldTime) onlyOwner crowdsaleNotStarted external {
        require(_tokenHoldTime != 0);
        if(_tokenHoldTime > 0) tokenHoldTime = _tokenHoldTime;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier canInit(bool permission) {
        require(permission);
        _;
    }

    modifier crowdsaleNotStarted() {
        require(startBlock == 0 || block.number < startBlock);
        _;
    }

}
