pragma solidity ^0.4.0;

import "../../DAO/Owned.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";
import "./OwnedFields.sol";

contract State is CrowdsaleDAOFields {
    address public owner;

    event State(address _comission);

    function initState(address _tokenAddress, address _votingFactory, address _serviceContract) external onlyOwner(msg.sender) canInit crowdsaleNotStarted {
        require(_tokenAddress != 0x0 && _votingFactory != 0x0 && _serviceContract != 0x0);

        token = TokenInterface(_tokenAddress);
        votingFactory = VotingFactoryInterface(_votingFactory);
        created_at = block.timestamp;

        serviceContract = _serviceContract;
        commissionContract = new Commission(this);

        canInitStateParameters = false;

        State(commissionContract);
    }

    modifier canInit() {
        require(canInitStateParameters);
        _;
    }

    modifier crowdsaleNotStarted() {
        require(startTime == 0 || block.timestamp < startTime);
        _;
    }

    modifier onlyOwner(address _sender) {
        require(_sender == owner);
        _;
    }
}
