pragma solidity 0.4.24;

library TypesConverter {
    function bytes32ToAddress(bytes32 input) public pure returns(address){
        return address(input);
    }

    function addressToBytes32(address input) public pure returns (bytes32){
        return bytes32(input);
    }

    function bytes32ToUint(bytes32 input) public pure returns (uint ret) {
        require(input != 0x0);

        uint digit;
        for (uint i = 0; i < 32; i++) {
            digit = uint((uint(input) / (2 ** (8 * (31 - i)))) & 0xff);
            if (digit == 0)  break;
            else if (digit < 48 || digit > 57) revert();
            ret *= 10;
            ret += (digit - 48);
        }

        return ret;
    }

    function uintToBytes32(uint input) public pure returns (bytes32 ret) {
        if (input == 0) ret = '0';
        else {
            while (input > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((input % 10) + 48) * 2 ** (8 * 31));
                input /= 10;
            }
        }
        return ret;
    }

    function bytes32ToString(bytes32 input) public pure returns(string) {
        bytes memory arrayTemp = new bytes(32);
        uint currentLength = 0;

        for (uint i = 0; i < 32; i++) {
            arrayTemp[i] = input[i];
            if (arrayTemp[i] != 0) currentLength+=1;
        }

        bytes memory arrayRes = new bytes(currentLength);
        for (i = 0; i < currentLength; i++) {
            arrayRes[i] = arrayTemp[i];
        }

        return string(arrayRes);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToBool(bytes32 input) public pure returns(bool) {
        return input == 0x0 ? false : true;
    }

    function boolToBytes32(bool input) public pure returns (bytes32) {
        return input ? bytes32(0x1) : bytes32(0x0);
    }
}
