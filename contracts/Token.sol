pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/token/BasicToken.sol';
import 'zeppelin-solidity/contracts/token/MintableToken.sol';

contract Token is MintableToken {
    string public constant name;
    string public constant symbol;
    uint public constant decimals;

    function Token(string _name, string _symbol, uint _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}
