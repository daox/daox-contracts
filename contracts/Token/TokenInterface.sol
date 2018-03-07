pragma solidity ^0.4.15;

interface TokenInterface {
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);
    function totalSupply() public constant returns (uint);
    function balanceOf(address _address) public constant returns (uint);
    function burn(address burner);
    function hold(address addr, uint duration) external;
    function transfer(address _to, uint _amount) external;
}
