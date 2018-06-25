pragma solidity 0.4.22;

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

    function handleDXCPayment(address _from, uint _dxcAmount) external CrowdsaleNotStarted onlyDXC {
        require(_dxcAmount >= 1, "Amount of DXC for initial deposit must be equal or greater than 1 DXC");

        initialDXCDeposit = _dxcAmount;
        votingPrice = _dxcAmount/10 != 0 ? _dxcAmount/10 : 1;
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

    modifier onlyDXC() {
        require(msg.sender == address(DXC), "Method can be called only from DXC contract");
        _;
    }
}
