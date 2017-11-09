pragma solidity ^0.4.11;

import "../Token.sol";
import "./DAO.sol";

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
    uint public weiRaised = 0;

    function CrowdsaleDAO(address _usersAddress, string _name, string _description, uint8 _minVote, address[] _participants, address _owner)
    DAO(_usersAddress, _name, _description, _minVote, _participants, _owner) {

    }

    function initTokenParameters(string _tokenName, string _tokenSymbol, uint _tokenDecimals) public {
        address _token = new Token(_tokenName, _tokenSymbol, _tokenDecimals);
        token = Token(_token);
    }

    function initCrowdsaleParameters(uint _softCap, uint _hardCap, uint _rate, uint _startBlock, uint _endBlock) public {
        softCap = _softCap;
        hardCap = _hardCap;

        startBlock = _startBlock;
        endBlock = _endBlock;

        rate = _rate;
    }

    function() payable {
        require(msg.sender != 0x0);
        require(validPurchase(msg.value));
        uint weiAmount = msg.value;

        //ToDo: rate in ethers or weis?
        uint tokensAmount = weiAmount * rate;

        // update state
        weiRaised = weiRaised + weiAmount;

        token.mint(msg.sender, tokensAmount);
        TokenPurchase(msg.sender, weiAmount, tokensAmount);

        //forwardFunds();
    }

    function validPurchase(uint value) constant returns(bool) {
        if (value * rate > hardCap) return false;
        if (block.number > endBlock) return false;
        //if (token.mintingFinished == true) return false; ToDo: do we need to check that?

        return true;
    }

    function finish() public onlyOwner {
        require(endBlock >= block.number);
        isCrowdsaleFinished = true;

        token.finishMinting();
    }
}