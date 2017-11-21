pragma solidity ^0.4.11;

import '../../node_modules/zeppelin-solidity/contracts/token/BasicToken.sol';
import '../../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';

contract Token is MintableToken {
    string public name;
    string public symbol;
    uint constant public decimals = 18;
    mapping(address => bool) holded;
    uint unholdTime = now;


    function Token(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function setHolding(uint _unholdTime) onlyOwner {
        unholdTime = _unholdTime;
    }

    function burn(address _burner) onlyOwner {
        require(_burner != 0x0);

        uint balance = balanceOf(_burner);
        balances[_burner] = balances[_burner].sub(balance);
        totalSupply = totalSupply.sub(balance);
    }

    function mint(address _to, uint256 _amount, bool hold) onlyOwner canMint public returns (bool) {
        require(_to != 0x0);
        if(hold) holded[_to] = true;
        super.mint(_to, _amount);
    }

    function transfer(address to, uint256 value) notHolded(msg.sender) public returns (bool) {
        super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) notHolded(from) public returns (bool) {
        super.transferFrom(from, to, value);
    }

    modifier notHolded(address _address) {
        require(!holded[_address] || now >= unholdTime);
        _;
    }
}
}
