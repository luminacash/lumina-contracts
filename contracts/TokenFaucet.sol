// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenFaucet is ERC20 {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function mint(uint supply) external {
        // Mint the requested supply to msg.sender
        uint8 decimals = decimals();
        _mint(msg.sender, supply * (10**decimals));
    }

}
