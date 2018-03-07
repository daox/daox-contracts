pragma solidity ^0.4.11;

import '../../node_modules/zeppelin-solidity/contracts/token/BasicToken.sol';
import '../../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';

contract Token is MintableToken {
    event TokenCreation(address _address);

    string public name;
    string public symbol;
    uint constant public decimals = 18;
    mapping(address => uint) public held;

    function Token(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
        TokenCreation(this);
    }

    function hold(address addr, uint duration) external onlyOwner {
        uint holdTime = now + duration;
        if (held[addr] == 0 || holdTime > held[addr]) held[addr] = holdTime;
    }

    function burn(address _burner) external onlyOwner {
        require(_burner != 0x0);

        uint balance = balanceOf(_burner);
        balances[_burner] = balances[_burner].sub(balance);
        totalSupply = totalSupply.sub(balance);
    }

    function allowAndTransfer(address _from, address _to, uint256 _amount) external notHolded(_from) onlyOwner {
        allowed[_from][_to] = _amount;
        super.transferFrom(_from, _to, _amount);
    }

    function transfer(address to, uint256 value) public notHolded(msg.sender) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public notHolded(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    modifier notHolded(address _address) {
        require(held[_address] == 0 || now >= held[_address]);
        _;
    }
}
