// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin contract.
 */
abstract contract OnlyAdmin is Context {
    address private _creatorAddr;
    address private _adminAddr;

    constructor() {
        _creatorAddr = _msgSender();
    }

    // OnlyCreator, OnlyOnce
    function attachAdmin(address adminAddr_) external {
        require(_creatorAddr == _msgSender(), "OnlyAdmin: only creator can attach a admin contract");
        require(_adminAddr == address(0), "OnlyAdmin: the admin contract has already been attached");
        _creatorAddr = address(0);
        _adminAddr = adminAddr_;
    }

    function adminAddr() public view returns (address) {
        return _adminAddr;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(adminAddr() == _msgSender(), "OnlyAdmin: conly admin can execute this function");
        _;
    }

}
