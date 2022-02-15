// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Progressing.sol";
import "./ProgressLocker.sol";
import "./Utils.sol";

contract ProgressContractLocker is ProgressLocker {
    address public progressingAddr;
    address public erc20Addr;

    constructor(address erc20Addr_, address progressingAddr_)
        ProgressLocker(Utils.concat("Locked ", ERC20(erc20Addr_).name()), Utils.concat("L", ERC20(erc20Addr_).symbol()), ERC20(erc20Addr_), Progressing(progressingAddr_)) {
        erc20Addr = erc20Addr_;
        progressingAddr = progressingAddr_;
    }
}
