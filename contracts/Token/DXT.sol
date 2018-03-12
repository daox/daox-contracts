pragma solidity ^0.4.11;

import '../../node_modules/zeppelin-solidity/contracts/token/BasicToken.sol';
import '../../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';

contract DXT is MintableToken {
    event TokenCreation(address _address);

    string public name;
    string public symbol;
    uint constant public decimals = 18;

    function DXT(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
        TokenCreation(this);
    }

    function contributeTo(address _to, uint256 _amount) public {
        super.transfer(_to, _amount);
        _to.call(bytes4(keccak256("handleDXTPayment(address,uint256)")), msg.sender, _amount);
    }
}
