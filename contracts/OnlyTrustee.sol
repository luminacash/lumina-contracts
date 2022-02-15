// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyTrustee`, which can be applied to your functions to restrict their use to
 * the trustee contract.
 */
abstract contract OnlyTrustee is Context {
    address private _creatorAddr;
    address private _trusteeAddr;

    constructor() {
        _creatorAddr = _msgSender();
    }

    // OnlyCreator, OnlyOnce
    function attachTrustee(address trusteeAddr_) external {
        require(_creatorAddr == _msgSender(), "OnlyTrustee: only creator can attach a trustee contract");
        require(_trusteeAddr == address(0), "OnlyTrustee: the trustee contract has already been attached");
        _creatorAddr = address(0);
        _trusteeAddr = trusteeAddr_;
    }

    function trusteeAddr() public view returns (address) {
        return _trusteeAddr;
    }

    /**
     * @dev Throws if called by any account other than the trustee.
     */
    modifier onlyTrustee() {
        require(trusteeAddr() == _msgSender(), "OnlyTrustee: only trustee can execute this function");
        _;
    }

}
