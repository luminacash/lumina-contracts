// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {

    // finds the highest significant bit of the argument
    // the result is encoded as if bits were numbered from 1
    // e.g. findHsb of 0 returns 0
    //      findHsb of 1 returns 1
    //      findHsb of 2 returns 2
    //      findHsb of 4 returns 3
    //      etc.
    function _findHsb(uint256 n) internal pure returns (uint16) {
        uint16 from = 0;
        uint16 to = 256;

        while(from < to) {
            uint16 middle = (from + to) >> 1;
            uint256 mask = (2 ** middle) - 1;
            if(n <= mask) {
                to = middle;
            } else {
                from = middle+1;
            }
        }

        return from;
    }

    // finds the lowest significant bit of the argument
    // the result is encoded as if bits were numbered from 1
    // e.g. findLsb of 0 returns 0
    //      findLsb of 1 returns 1
    //      findLsb of 2 returns 2
    //      findLsb of 4 returns 3
    //      etc.
    function _findLsb(uint256 n) internal pure returns (uint16) {
        if(n == 0) {
            return 0;
        }
        uint16 from = 1;
        uint16 to = 256;

        while(from < to) {
            uint16 middle = (from + to) >> 1;
            uint256 mask = (2 ** middle) - 1;
            if((n & mask) == 0) {
                from = middle+1;
            } else {
                to = middle;
            }
        }

        return from;
    }

    function concat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

}
