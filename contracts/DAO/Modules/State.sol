pragma solidity ^0.4.0;

import "../../DAO/Owned.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "./OwnedFields.sol";

contract State is CrowdsaleDAOFields {
    function initState(uint _minVote, address _tokenAddress, address _votingFactory, address _serviceContract) external canInit {
        require(_tokenAddress != 0x0 && _votingFactory != 0x0 && _serviceContract != 0x0);

        token = TokenInterface(_tokenAddress);
        votingFactory = VotingFactoryInterface(_votingFactory);
        minVote = _minVote;
        participants[msg.sender] = true;
        created_at = block.timestamp;

        serviceContract = _serviceContract;
        commissionContract = new Commission(this);

        canInitStateParameters = false;
    }

    function initHold(uint _tokenHoldTime) crowdsaleNotStarted external {
        require(_tokenHoldTime != 0);
        if(_tokenHoldTime > 0) tokenHoldTime = _tokenHoldTime;
    }

    modifier canInit() {
        require(canInitStateParameters);
        _;
    }

    modifier crowdsaleNotStarted() {
        require(startBlock == 0 || block.number < startBlock);
        _;
    }
}
