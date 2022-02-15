// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChallengeRecords.sol";

interface ILuminaAdmin {

    function readChallenges(bool premium, uint8 limit) external view returns (uint8 totalCnt, uint8[] memory indexes, uint64[] memory blockNumbers, uint16[] memory rewardUnits, uint256[] memory challengeHashes, uint8[] memory nexts, uint16[] memory claimsCnt, bool[] memory claimed);
    function getChallengesAllowance() external view returns (uint8);
    function addChallenges(uint8 limit) external returns (uint8);
    function retrieveChallenge(uint64 blockNumber) external view returns (ChallengeRecords.Challenge memory ch, bool premium, uint8 generalDifficulty);
    function _cleanupChallenge(uint64 blockNumber, bool premium) external; // onlyTrustee
}
