pragma solidity ^0.4.11;

import '../../node_modules/zeppelin-solidity/contracts/token/BasicToken.sol';
import '../../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';

contract DXC is MintableToken {
    address[] public additionalOwnersList; // List of addresses which are able to call `mint` function
    mapping(address => bool) public additionalOwners;  // Mapping of addresses which are able to call `mint` function
    uint public maximumSupply = 300000000 * 10**18; // Maximum supply of DXC tokens equals 300 millions

    event TokenCreation(address _address);
    event SetAdditionalOwners(address[] oldOwners, address[] newOwners);

    string public constant name = "Daox Coin";
    string public constant symbol = "DXC";
    uint public constant decimals = 18;


    function contributeTo(address _to, uint256 _amount) public {
        super.transfer(_to, _amount);
        require(_to.call(bytes4(keccak256("handleDXCPayment(address,uint256)")), msg.sender, _amount));
    }

    /**
     * @dev Overrides function to mint tokens from `MintableToken` contract with new modifier
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) isOwnerOrAdditionalOwner canMint maximumSupplyWasNotReached(_amount) public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    /**
     * @dev Define array and mapping of addresses that will be additional owners
     * @param _owners The addresses that will be defined as additional owners
    */
    function setAdditionalOwners(address[] _owners) onlyOwner {
        SetAdditionalOwners(additionalOwnersList, _owners);

        for (uint i = 0; i < additionalOwnersList.length; i++) {
            additionalOwners[additionalOwnersList[i]] = false;
        }

        for (i = 0; i < _owners.length; i++) {
            additionalOwners[_owners[i]] = true;
        }

        additionalOwnersList = _owners;
    }

    /**
     * @dev Throws an exception if called not by owner or additional owner
     */
    modifier isOwnerOrAdditionalOwner() {
        require(msg.sender == owner || additionalOwners[msg.sender]);
        _;
    }

    /**
     * @dev Throws an exception if maximumSupply will be exceeded after minting
     * @param _amount The amount of tokens to mint
     */
    modifier maximumSupplyWasNotReached(uint256 _amount) {
        require(totalSupply.add(_amount) <= maximumSupply);
        _;
    }
}
