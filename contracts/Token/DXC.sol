pragma solidity ^0.4.11;

import '../../node_modules/zeppelin-solidity/contracts/token/BasicToken.sol';
import '../../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';

contract DXC is MintableToken {
    event TokenCreation(address _address);

    string public constant name = "DAOX Coin";
    string public constant symbol = "DXC";
    uint public constant decimals = 18;

    function contributeTo(address _to, uint256 _amount) public {
        super.transfer(_to, _amount);
        require(_to.call(bytes4(keccak256("handleDXCPayment(address,uint256)")), msg.sender, _amount));
    }
}
