// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Parameters.sol";
import "./Utils.sol";

abstract contract Rules is Parameters {
    using SafeMath for uint256;

    function _getWalletDifficultyDiscount(uint256 challengeHash, address addr, uint256 balance) internal pure returns (uint8) {
        uint256 h1 = challengeHash;
        uint256 h2 = uint256(uint160(addr));

        uint256 o = h1 ^ h2;
        uint16 lsb = Utils._findLsb(o);
        if(lsb == 0) {
            lsb = 256;
        } else {
            lsb--;
        }

        uint256 b1 = balance.div(TOKEN_UNIT);
        uint8 n = 0;
        if(b1 >= 1) {
            if(lsb >= 20) {
                n = 30;
            } else if(lsb >= 10) {
                n = 20 + (uint8(lsb) - 10);
            } else {
                n = 2 * uint8(lsb);
            }
        } else {
            if(lsb > 10) {
                n = 10;
            } else {
                n = uint8(lsb);
            }
        }

        return n;
    }

   function _getBalanceDifficultyDiscount(uint256 balance) internal pure returns (uint8) {
        uint256 b1 = balance.div(TOKEN_UNIT);
        uint256 b2 = balance.mod(TOKEN_UNIT).div(REWARD_UNIT);

        uint8 discount;
        if(b1 >= 1) {
            if(b1 >= 1000) {
                discount = 2 * 10 + 10;
            } else if(b1 >= 500) {
                discount = 2 * 9 + 10;
            } else if(b1 >= 200) {
                discount = 2 * 8 + 10;
            } else if(b1 >= 100) {
                discount = 2 * 7 + 10;
            } else if(b1 >= 50) {
                discount = 2 * 6 + 10;
            } else if(b1 >= 20) {
                discount = 2 * 5 + 10;
            } else if(b1 >= 10) {
                discount = 2 * 4 + 10;
            } else if(b1 >= 5) {
                discount = 2 * 3 + 10;
            } else if(b1 >= 3) {
                discount = 2 * 2 + 10;
            } else if(b1 >= 2) {
                discount = 2 * 1 + 10;
            } else {
                discount = 2 * 0 + 10;
            }
        } else {
            if(b2 >= 500) {
                discount = 9;
            } else if(b2 >= 200) {
                discount = 8;
            } else if(b2 >= 100) {
                discount = 7;
            } else if(b2 >= 50) {
                discount = 6;
            } else if(b2 >= 20) {
                discount = 5;
            } else if(b2 >= 10) {
                discount = 4;
            } else if(b2 >= 5) {
                discount = 3;
            } else if(b2 >= 2) {
                discount = 2;
            } else if(b2 >= 1) {
                discount = 1;
            } else {
                discount = 0;
            }
        }
        return discount;
    }

    // Now of tokens is means in Einstein era, during Newton era the number need to be multiplies with current units per token number
    function _getRewardTokens(uint256 challengeHash) internal pure returns (uint16 rewardsCnt, uint16 tokens) {
        uint256 h = challengeHash;

        if(((h >> (256-20)) & 0xFFFFF) == 0x22222) {
            return (500, 2000);
        } else if(((h >> (256-16)) & 0xFFFF) == 0x2222) {
            return (200, 500);
        } else if(((h >> (256-12)) & 0xFFF) == 0x222) {
            return (100, 100);
        } else if(((h >> (256-2)) & 0xFF) == 0x22) {
            return (50, 20);
        } else if(((h >> (256-4)) & 0xF) == 0x2) {
            return (20, 5);
        } else {
            return (10, 1);
        }
    }

}
