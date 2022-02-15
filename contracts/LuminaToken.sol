// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ILuminaRecords.sol";

contract LuminaToken is ERC20 {
    // Public address of the linked token contract
    address public recordsAddr;
    // Link to the records contract
    ILuminaRecords private records;

    constructor(string memory name, string memory symbol, uint initSupply, address recordsAddr_) ERC20(name, symbol) {
        // Mint initial supply to msg.sender
        uint8 decimals = decimals();
        require(decimals == 18);
        _mint(msg.sender, initSupply * (10**decimals));

        // Register the records contract address
        recordsAddr = recordsAddr_;
        records = ILuminaRecords(recordsAddr_);
     }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        super._transfer(sender, recipient, amount);

        try records._updateBalance(sender, balanceOf(sender)) {
        } catch {
        }

        try records._registerBalance(recipient, balanceOf(recipient), false) {
        } catch {
        }
    }

    function registerBalance() public {
        uint256 balance = balanceOf(msg.sender);
        records._registerBalance(msg.sender, balance, true);
    }

}
