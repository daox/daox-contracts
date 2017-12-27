pragma solidity ^0.4.0;

import "../../DAO/Owned.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "./OwnedFields.sol";

contract State is CrowdsaleDAOFields {
    address public owner;

    event State(address _comission);

    function initState(uint _minVote, address _tokenAddress, address _votingFactory, address _serviceContract) external onlyOwner(msg.sender) canInit {
        require(_tokenAddress != 0x0 && _votingFactory != 0x0 && _serviceContract != 0x0);

        token = TokenInterface(_tokenAddress);
        votingFactory = VotingFactoryInterface(_votingFactory);
        minVote = _minVote;
        created_at = block.timestamp;

        serviceContract = _serviceContract;
        commissionContract = new Commission(this);

        canInitStateParameters = false;

        State(commissionContract);
    }

    function initHold(uint _tokenHoldTime) onlyOwner(msg.sender) crowdsaleNotStarted external {
        require(_tokenHoldTime > 0);
        tokenHoldTime = _tokenHoldTime;
    }

    modifier canInit() {
        require(canInitStateParameters);
        _;
    }

    modifier crowdsaleNotStarted() {
        require(startBlock == 0 || block.number < startBlock);
        _;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }
}
