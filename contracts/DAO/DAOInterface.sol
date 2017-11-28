pragma solidity ^0.4.11;

interface DAOInterface {
    function isParticipant(address participantAddress) constant returns (bool);

    function participantsCount() public constant returns(uint);

    function withdrawal(address _address, uint withdrawalSum);

    function makeRefundable();

    function flushWhiteList() external;

    function changeWhiteList(address _addr, bool res) external;

    function holdTokens(address _address, uint duration) external;
}
