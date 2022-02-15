// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILuminaMarketing {

    function owner() external view returns (address);
    function _claim(uint64 blockNumber, address miner, address recipient, uint32 rewardUnits, uint8 commisionPrc) external; // onlyTrustee

}
