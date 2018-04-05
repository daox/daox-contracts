pragma solidity ^0.4.11;

library Common {
    function stringToBytes32(string memory source) constant returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function percent(uint numerator, uint denominator, uint precision) constant returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        quotient =  ((_numerator / denominator) + 5) / 10;
    }

    function toString(bytes32 _bytes) internal constant returns(string) {
        bytes memory arrayTemp = new bytes(32);
        uint currentLength = 0;

        for (uint i = 0; i < 32; i++) {
            arrayTemp[i] = _bytes[i];
            if (arrayTemp[i] != 0) currentLength+=1;
        }

        bytes memory arrayRes = new bytes(currentLength);
        for (i = 0; i < currentLength; i++) {
            arrayRes[i] = arrayTemp[i];
        }

        return string(arrayRes);
    }
}
