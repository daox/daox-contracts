pragma solidity ^0.4.11;

import '../../node_modules/zeppelin-solidity/contracts/token/BasicToken.sol';
import '../../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';

contract Token is MintableToken {
    string public name;
    string public symbol;
    uint constant public decimals = 18;

    function Token(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function burn(address _burner) onlyOwner {
        require(_burner != 0x0);

        uint balance = balanceOf(_burner);
        balances[_burner] = balances[_burner].sub(balance);
        totalSupply = totalSupply.sub(balance);
    }
}
