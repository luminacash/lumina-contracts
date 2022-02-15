// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @dev Interface that provides a progress indicator expressed a pair of two numbers, a progress number and a progresMax number representing 100%.
*
* Progress(%): p = progress * 100 / progressMax
*/
interface Progressing {
    function getProgress() external view returns (uint256 progress, uint256 progressMax);
}
