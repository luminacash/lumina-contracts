// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyToken`, which can be applied to your functions to restrict their use to
 * the token contract.
 */
abstract contract OnlyToken is Context {
    address private _creatorAddr;
    address private _tokenAddr;

    constructor() {
        _creatorAddr = _msgSender();
    }

    // OnlyCreator, OnlyOnce
    function attachToken(address tokenAddr_) external {
        require(_creatorAddr == _msgSender(), "OnlyToken: only creator can attach a token contract");
        require(_tokenAddr == address(0), "OnlyToken: the token contract has already been attached");
        _creatorAddr = address(0);
        _tokenAddr = tokenAddr_;
    }

    function tokenAddr() public view returns (address) {
        return _tokenAddr;
    }

    /**
     * @dev Throws if called by any account other than the token.
     */
    modifier onlyToken() {
        require(tokenAddr() == _msgSender(), "OnlyToken: only token can execute this function");
        _;
    }

}
