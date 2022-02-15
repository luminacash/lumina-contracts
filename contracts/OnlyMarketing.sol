// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * This module is used through inheritance. It will make available the modifier
 * `onlyMarketing`, which can be applied to your functions to restrict their use to
 * the marketing contract.
 */
abstract contract OnlyMarketing is Context {
    address private _marketingAddr;

    constructor(address marketingAddr_) {
        _marketingAddr = marketingAddr_;
    }

    function marketingAddr() public view returns (address) {
        return _marketingAddr;
    }

    /**
     * @dev Throws if called by any account other than the marketing.
     */
    modifier onlyMarketing() {
        require(marketingAddr() == _msgSender(), "OnlyMarketing: only marketing can execute this function");
        _;
    }

}
