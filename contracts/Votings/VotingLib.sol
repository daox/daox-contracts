pragma solidity 0.4.24;

import "../DAO/ICrowdsaleDAO.sol";
import "../DAO/API/IService.sol";
import "../Common.sol";

library VotingLib {
    struct Option {
        uint votes;
        bytes32 description;
    }

    function delegatecallCreate(address _v, address _dao, string _name, string _description, uint _duration, uint _quorum) {
        require(_v.delegatecall(bytes4(keccak256("create(address,bytes32,bytes32,uint256,uint256)")),
            _dao,
            Common.stringToBytes32(_name),
            Common.stringToBytes32(_description),
            _duration,
            _quorum)
        );
    }

    function delegatecallAddVote(address _v, uint optionID) {
        require(_v.delegatecall(bytes4(keccak256("addVote(uint256)")), optionID));
    }

    function delegatecallFinish(address _v) {
        require(_v.delegatecall(bytes4(keccak256("finish()"))));
    }

    function isValidWithdrawal(address _dao, uint _sum, bool _dxc) constant returns(bool) {
        return !_dxc ? _dao.balance >= _sum  : (ICrowdsaleDAO(_dao).DXC().balanceOf(_dao) - ICrowdsaleDAO(_dao).initialCapital()) >= _sum;
    }

    function checkServicePrice(string action, address _dao, address _service) internal {
        uint price = keccak256(action) == keccak256("call") ? IService(_service).priceToCall() : IService(_service).priceToConnect();
        require(price <= ICrowdsaleDAO(_dao).initialCapital(), "Not enough DXC in initial capital to connect this service");
    }

    function serviceConnected(address _dao, address _service) view returns(bool) {
        return ICrowdsaleDAO(_dao).services(_service);
    }
}