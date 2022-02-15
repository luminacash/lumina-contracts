// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILuminaRecords {

    function getBalances() external view returns (uint256[] memory balances, uint64[] memory blockNumbers);
    function findBalance(address wallet, uint64 blockNumber) external view returns (uint256 balance);
    function getClaimsCnt(uint64 blockNumber) external view returns (uint16);
    function hasClaimed(uint64 blockNumber, address recipient) external view returns (uint32 rewardUnits);
    function getClaims(uint64[] memory blockNumbers, address recipient) external view returns (uint16[] memory claimsCnt, bool[] memory claimed);
    function setCommision(uint8 commisionPrc) external;
    function getCommision(address wallet) external view returns (uint8 commisionPrc);
    function _registerBalance(address sender, uint256 balance, bool force) external returns (bool registered); // onlyToken
    function _updateBalance(address sender, uint256 balance) external; // onlyToken
    function _addClaim(uint64 blockNumber, address recipient, uint32 rewardUnits) external; // onlyTrustee
    function _updateFirstBlockNumber(uint64 blockNumber) external; // onlyAdmin

}
