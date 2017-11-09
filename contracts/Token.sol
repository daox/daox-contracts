pragma solidity ^0.4.11;

import '../node_modules/zeppelin-solidity/contracts/token/BasicToken.sol';
import '../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';

contract Token is MintableToken {
    string public name;
    string public symbol;
    uint public decimals;

    function Token(string _name, string _symbol, uint _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}