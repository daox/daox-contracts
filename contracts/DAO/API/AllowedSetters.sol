pragma solidity 0.4.24;

import "./TypesConverter.sol";
import "../CrowdsaleDAOFields.sol";
import "../../Token/TokenInterface.sol";

contract AllowedSetters is CrowdsaleDAOFields {
        mapping(bytes32 => bytes32) public signatures;

        constructor() {
            signatures["setEtherRate"] = "setEtherRate(bytes32)";
            signatures["setDXCRate"] = "setDXCRate(bytes32)";
            signatures["setSoftCap"] = "setSoftCap(bytes32)";
            signatures["setHardCap"] = "setHardCap(bytes32)";
            signatures["setStartTime"] = "setStartTime(bytes32)";
            signatures["setEndTime"] = "setEndTime(bytes32)";
            signatures["setCanInitCrowdsale"] = "setCanInitCrowdsale(bytes32)";
            signatures["setCanInitState"] = "setCanInitState(bytes32)";
            signatures["setCanInitBonuses"] = "setCanInitBonuses(bytes32)";
            signatures["setNewEtherRate"] = "setNewEtherRate(bytes32)";
            signatures["newDXCRate"] = "newDXCRate(bytes32)";
            signatures["setToken"] = "setToken(bytes32)";
            signatures["setName"] = "setName(bytes32)";
            signatures["setDescription"] = "setDescription(bytes32)";
            signatures["setDxcPayments"] = "setDxcPayments(bytes32)";
            signatures["setLockup"] = "setLockup(bytes32)";
            signatures["setVotingPrice"] = "setVotingPrice(bytes32)";
        }

        function setEtherRate(bytes32 _etherRate) external onlyServiceProxy {
            etherRate = TypesConverter.bytes32ToUint(_etherRate);
        }

        function setDXCRate(bytes32 _DXCRate) external onlyServiceProxy {
            DXCRate = TypesConverter.bytes32ToUint(_DXCRate);
        }

        function setSoftCap(bytes32 _softCap) external onlyServiceProxy {
            softCap = TypesConverter.bytes32ToUint(_softCap);
        }

        function setHardCap(bytes32 _hardCap) external onlyServiceProxy {
            hardCap = TypesConverter.bytes32ToUint(_hardCap);
        }

        function setStartTime(bytes32 _startTime) external onlyServiceProxy {
            startTime = TypesConverter.bytes32ToUint(_startTime);
        }

        function setEndTime(bytes32 _endTime) external onlyServiceProxy {
            endTime = TypesConverter.bytes32ToUint(_endTime);
        }

        function setCanInitCrowdsale(bytes32 _canInitCrowdsaleParameters) external onlyServiceProxy {
            canInitCrowdsaleParameters = TypesConverter.bytes32ToBool(_canInitCrowdsaleParameters);
        }

        function setCanInitState(bytes32 _canInitStateParameters) external onlyServiceProxy {
            canInitStateParameters = TypesConverter.bytes32ToBool(_canInitStateParameters);
        }

        function setCanInitBonuses(bytes32 _canInitBonuses) external onlyServiceProxy {
            canInitBonuses = TypesConverter.bytes32ToBool(_canInitBonuses);
        }

        function setNewEtherRate(bytes32 _newEtherRate) external onlyServiceProxy {
            newEtherRate = TypesConverter.bytes32ToUint(_newEtherRate);
        }

        function setNewDXCRate(bytes32 _newDXCRate) external onlyServiceProxy {
            newDXCRate = TypesConverter.bytes32ToUint(_newDXCRate);
        }

        function setToken(bytes32 _token) external onlyServiceProxy {
            token = TokenInterface(TypesConverter.bytes32ToAddress(_token));
        }

        function setName(bytes32 _name) external onlyServiceProxy {
            name = TypesConverter.bytes32ToString(_name);
        }

        function setDescription(bytes32 _description) external onlyServiceProxy {
            description = TypesConverter.bytes32ToString(_description);
        }

        function setDxcPayments(bytes32 _dxcPayments) external onlyServiceProxy {
            dxcPayments = TypesConverter.bytes32ToBool(_dxcPayments);
        }

        function setLockup(bytes32 _lockup) external onlyServiceProxy {
            lockup = TypesConverter.bytes32ToUint(_lockup);
        }

        function setVotingPrice(bytes32 _votingPrice) external onlyServiceProxy {
            votingPrice = TypesConverter.bytes32ToUint(_votingPrice);
        }

        modifier onlyServiceProxy() {
            require(msg.sender == proxyAPI, "Methods can only be called by proxy contract for remote services");
            _;
        }
}