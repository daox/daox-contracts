pragma solidity ^0.4.0;

import "../../DAO/Owned.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Commission.sol";

contract State is CrowdsaleDAOFields {
    address public owner;

    event State(address _comission);

    /*
    * @dev Sets addresses of token which will be minted during the crowdsale and address of DXC token contract so that
    *      DAO will be able to handle investments via DXC. Also function creates instance of Commission contract for this DAO
    * @param value Amount of sent funds
    */
    function initState(address _tokenAddress, address _DXC)
        external
        onlyOwner(msg.sender)
        canInit
        crowdsaleNotStarted
    {
        require(_tokenAddress != 0x0 && _DXC != 0x0);

        token = TokenInterface(_tokenAddress);
        DXC = TokenInterface(_DXC);

        created_at = block.timestamp;

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
