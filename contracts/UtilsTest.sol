// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

contract UtilsTest {

        function findHsb(uint256 n) public pure returns (uint16) {
            return Utils._findHsb(n);
        }

        function findLsb(uint256 n) public pure returns (uint16) {
            return Utils._findLsb(n);
        }

}
