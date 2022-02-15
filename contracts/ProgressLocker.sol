// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Progressing.sol";

abstract contract ProgressLocker is ERC20 {
    using SafeMath for uint256;

    // Link to ERC20 tokens contract
    IERC20 private erc20;

    // Link to contract or object with progressing indicator
    Progressing private progressing;

    // Mapping address to adjustment
    // Adjustment basically relects the amoutn withdrawn form the account
    // but it gets more compicated opnce you start tranferring locked tokens to other accounts
    //
    // available = (balance + adjustment) * progress / progressMax - adjustment
    //
    mapping (address => uint256) private _adjustment;

    // True amount withdrawn from each account
    mapping (address => uint256) private _withdrawn;

    constructor(string memory name_, string memory symbol_, IERC20 erc20_, Progressing progressing_)
        ERC20(name_, symbol_)
    {
        erc20 = erc20_;
        progressing = progressing_;

        // Just check if all is good
        progressing.getProgress();
    }

    function totalLockedBalance() public view returns (uint256) {
        uint256 total = erc20.balanceOf(address(this));
        return total;
    }

    function deposit(uint256 amount) public {
        address sender = msg.sender;
        address recipient = address(this);
        erc20.transferFrom(sender, recipient, amount);
        _mint(sender, amount);
        (uint256 progress, uint256 progressMax) = progressing.getProgress();
        (progress, progressMax) = progressing.getProgress();
        if(progress > 0) {
            require(progress < progressMax, "ProgressLocker: progress is 100%, it does not make any sense to deposit anymore");
            uint256 aamount = depositAdjustment(amount, progress, progressMax, decimals());
            _adjustment[sender] = _adjustment[sender].add(aamount);
        }
    }

    // (amount + adj) * progress / progressMax == adj, therefore
    // adj = (amount * progress/progressMax) / (1 - progress/progressMax)
    function depositAdjustment(uint256 amount, uint256 progress, uint256 progressMax, uint8 decimals) private pure returns (uint256) {
        uint256 a = amount.mul(progress).div(progressMax);
        uint256 m = 10 ** decimals;
        uint256 p = m.mul(progress).div(progressMax);
        uint256 b = m.sub(p);
        uint256 adj = a.mul(m).div(b);
        return adj;
    }

    function withdraw(uint256 amount) public {
        address sender = msg.sender;
        uint256 available = availableBalanceOf(sender);
        require(amount <= available, "ProgressLocker: Withdrawal exceeds the available amount");
        uint256 adjustment = adjustmentBalanceOf(sender);
        _adjustment[sender] = adjustment.add(amount);
        uint256 withdrawn = withdrawnBalanceOf(sender);
        _withdrawn[sender] = withdrawn.add(amount);
        _burn(sender, amount);
        erc20.transfer(sender, amount);
    }

    function withdrawAll() public {
        address sender = msg.sender;
        uint256 amount = availableBalanceOf(sender);
        uint256 adjustment = adjustmentBalanceOf(sender);
        _adjustment[sender] = adjustment.add(amount);
        uint256 withdrawn = withdrawnBalanceOf(sender);
        _withdrawn[sender] = withdrawn.add(amount);
        _burn(sender, amount);
        erc20.transfer(sender, amount);
    }

    // available = (balance + adjustment) * progress / progressMax - adjustment
    function availableBalanceOf(address account) public view returns (uint256) {
        uint256 balance = balanceOf(account);
        // Let's call progressing directly so we can test returned values
        (uint256 progress, uint256 progressMax) = progressing.getProgress();
        if(progress == 0) {
            return 0;
        }
        if(progress >= progressMax) {
            return balance;
        }
        uint256 adjustment = adjustmentBalanceOf(account);
        uint256 totalWithdraw = balance.add(adjustment).mul(progress).div(progressMax, "ProgressLocker: zero progressMax");
        if(totalWithdraw > adjustment) {
            return totalWithdraw.sub(adjustment);
        }
        return 0;
    }

    function notAvailableBalanceOf(address account) public view returns (uint256) {
        uint256 total = balanceOf(account);
        uint256 available = availableBalanceOf(account);
        return total.sub(available);
    }

    function withdrawnBalanceOf(address account) public view returns (uint256) {
        uint256 withdrawn = _withdrawn[account];
        return withdrawn;
    }

    function adjustmentBalanceOf(address account) private view returns (uint256) {
        uint256 adjustment = _adjustment[account];
        return adjustment;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 balance = balanceOf(sender);
        super._transfer(sender, recipient, amount);
        if(amount > 0) {
            uint256 adjustment = adjustmentBalanceOf(sender);
            uint256 aamount = adjustment.mul(amount).div(balance, "ProgressLocker: zero balance");
            _adjustment[sender] = adjustment.sub(aamount);
            _adjustment[recipient] = _adjustment[recipient].add(aamount);
        }
    }
}
