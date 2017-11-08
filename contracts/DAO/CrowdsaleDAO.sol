pragma solidity ^0.4.11;

import "../Token.sol";

contract CrowdsaleDAO is DAO {
    /*
    Emits when someone send ether to the contract
    and successfully buy tokens
    */
    event TokenPurchase (
        address beneficiary,
        uint weiAmount,
        uint tokensAmount
    );

    Token public token;
    uint public rate;
    uint softCap;
    uint hardCap;
    uint startBlock;
    uint endBlock;
    bool isCrowdsaleFinished = false;

    function CrowdsaleDAO(address _usersAddress, string _name, string _description, uint8 _minVote, address[] _participants,
    uint _softCap, uint _hardCap, uint rate, string _tokenName, string _tokenSymbol, uint _tokenDecimals, uint _startBlock, uint _endBlock)
    DAO(_usersAddress, _name, _description, _minVote, _participants) {
        softCap = _softCap;
        hardCap = _hardCap;

        startBlock = _startBlock;
        endBlock = _endBlock;

        createToken(_tokenName, _tokenSymbol, _tokenDecimals);
    }

    function() payable {
        require(msg.sender != 0x0);
        require(validPurchase(msg.value));
        uint weiAmount = msg.value;

        //ToDo: rate in ethers or weis?
        uint tokensAmount = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokensAmount);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        //forwardFunds();
    }

    function validPurchase(uint value) constant returns(bool) {
        if (value * rate > hardCap) return false;
        if (block.number > endBlock) return false;
        require(token.canMint());

        return true;
    }

    function finish() public onlyOwner {
        require(endBlock >= block.number);
        isCrowdsaleFinished = true;

        token.finishMinting();
    }

    function createToken(string _name, string _symbol, uint _decimals) {
        address _token = new Token(_name, _symbol, _decimals);
        token = Token(_token);
    }
}
