// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Progressing.sol";
import "./Rules.sol";
import "./ILuminaRecords.sol";
import "./ILuminaAdmin.sol";
import "./ILuminaMarketing.sol";
import "./ILuminaFund.sol";

contract LuminaTrustee is Ownable, Pausable, Progressing, Rules {
    using SafeMath for uint256;

    // Public address of the linked token contract
    address public tokenAddr;
    // Public address of the linked records contract
    address public recordsAddr;
    // Public address of the linked administrator contract
    address public adminAddr;
    // Public address of the linked marketing contract
    address public marketingAddr;

    // Link to ERC20 tokens contract
    IERC20 private token;
    // Link to LuminaRecords contract
    ILuminaRecords private records;
    // Link to LuminaAdministator contract
    ILuminaAdmin private admin;

    uint64 private _claimedChallenges;
    uint256 private _claimedTokens;
    uint64 private _marketingCallSuccessCnt;
    uint64 private _marketingCallFailedCnt;

    event Claim(uint64 indexed blockNumber, address indexed recipient, address indexed miner, uint256 solution, uint8 commisionPrc, uint16 claimNo);
    event MarketingCallFailed(address marketingAddr, uint64 blockNumber, string message);

    constructor(address tokenAddr_, address recordsAddr_, address adminAddr_) {
        pause();

        tokenAddr = tokenAddr_;
        recordsAddr = recordsAddr_;
        adminAddr = adminAddr_;
        token = IERC20(tokenAddr);
        records = ILuminaRecords(recordsAddr);
        admin = ILuminaAdmin(adminAddr);

        _claimedChallenges = 0;
        _claimedTokens = 0;
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

    function renounceOwnership() public virtual override onlyOwner whenNotPaused {
        super.renounceOwnership();
    }

    function getProgress() public view override returns (uint256 progress, uint256 progressMax) {
        progress = _claimedTokens;
        progressMax = _claimedTokens+token.balanceOf(address(this));
    }

    function getClaimedTokens() public view returns (uint256) {
        return _claimedTokens;
    }

    function setMarketingAddr(address marketingAddr_) external onlyOwner {
        require(marketingAddr_ == address(0) || ILuminaMarketing(marketingAddr_).owner() == owner(), "The marketing contract address must point to a contract with the same owner");
        marketingAddr = marketingAddr_;
    }

    function _getAdjustedDifficulty(uint64 blockNumber, address recipient, uint8 generalDifficulty, uint256 challengeHash) private view returns (uint8 adjustedDifficulty) {
        uint256 registeredBalance = records.findBalance(recipient, blockNumber);

        uint8 walletDiscount = _getWalletDifficultyDiscount(challengeHash, recipient, registeredBalance);
        uint8 balanceDiscount = _getBalanceDifficultyDiscount(registeredBalance);

        // Calculate Adjusted Difficulty
        require(MIN_CHALLENGE_DIFFICULTY <= generalDifficulty && generalDifficulty <= MAX_CHALLENGE_DIFFICULTY, "verifyClaim(): generalDifficulty out of range");
        uint8 totalDiscount = walletDiscount + balanceDiscount;
        adjustedDifficulty = generalDifficulty >= totalDiscount ? generalDifficulty - totalDiscount : 0;
        if(adjustedDifficulty < MIN_CHALLENGE_DIFFICULTY) {
            adjustedDifficulty = MIN_CHALLENGE_DIFFICULTY;
        }
        require(MIN_CHALLENGE_DIFFICULTY <= adjustedDifficulty && adjustedDifficulty <= MAX_CHALLENGE_DIFFICULTY, "verifyClaim(): adjustedDifficulty out of range");
    }

    function verifySolution(uint64 blockNumber, address miner, address recipient, uint256 solution) public view whenNotPaused returns (uint16 solvedDifficulty) {
        (ChallengeRecords.Challenge memory ch, bool premium, uint8 generalDifficulty) = admin.retrieveChallenge(blockNumber);

        require(MIN_CHALLENGE_DIFFICULTY <= generalDifficulty && generalDifficulty <= MAX_CHALLENGE_DIFFICULTY, "Difficulty is out of range");
        require(premium == false || premium == true);

        bytes memory data = abi.encodePacked(solution, ch.challengeHash, uint256(uint160(recipient)), uint256(uint160(miner)));
        require(data.length == 128, "Invalid solution data");
        bytes32 digest = keccak256(data);

        solvedDifficulty = 256 - Utils._findHsb(uint256(digest));
    }

    function _isLuminaFund(address recipient) private pure returns (bool) {
        ILuminaFund maybeFund = ILuminaFund(recipient);
        try maybeFund.isLuminaFund() returns (bool isFund) {
            return isFund;
        } catch {
            return false;
        }
    }

    // Reasons
    // 0 - satisfies all criteria, at this moment, to claim the tokens
    // 1 - blockNumber does not exist or has no live challenge assigned right now
    // 2 - solvedDifficulty doesn't safisfy the current requirements
    // 3 - this challenge has already been claimed by this address
    // 4 - all available rewards have been already claimed
    // 5 - recipient's address is not eligible for rewards, external miners can only make claims on addresses with at least 0.001 LUMI
    // 6 - recipient's address is not eligible for rewards, it is a contract that is not a Lumina Fund
    function verifyClaim(uint64 blockNumber, address miner, address recipient, uint256 solution) public view whenNotPaused
        returns (uint32 rewardUnits, uint8 reason, bool premium, uint16 rewardsCnt, uint16 claimsCnt)
    {
        ChallengeRecords.Challenge memory ch;

        // Retrieve the challenge information
        uint8 generalDifficulty;
        (ch, premium, generalDifficulty) = admin.retrieveChallenge(blockNumber);

        require(ch.valid, "Invalid challenge record");

        // Get adjustd difficulty
        uint8 adjustedDifficulty = _getAdjustedDifficulty(blockNumber, recipient, generalDifficulty, ch.challengeHash);

        // Get actual solved difficulty
        uint16 solvedDifficulty = verifySolution(blockNumber, miner, recipient, solution);

        // Calculate Reward Tokens
        rewardUnits = 0;
        reason = 0;
        if(solvedDifficulty >= adjustedDifficulty) {
            uint256 balance = token.balanceOf(recipient);
            if(records.hasClaimed(blockNumber, recipient) != 0) {
                reason = 3;
            } else if(miner != recipient && balance < MINERS_CLAIM_MIN_RECIPIENT_BALANCE) {
                reason = 5;
            } else if(Address.isContract(recipient) && !_isLuminaFund(recipient)) {
                reason = 6;
            }
        } else {
            reason = 2;
        }

        if(reason == 0) {
            uint16 rewardTokens;
            (rewardsCnt, rewardTokens) = _getRewardTokens(ch.challengeHash);

            if(rewardsCnt > REWARDS_CNT_LIMIT) {
                rewardsCnt = REWARDS_CNT_LIMIT;
            }

            claimsCnt = records.getClaimsCnt(blockNumber);
            if(claimsCnt < rewardsCnt) {
                rewardUnits = uint32(rewardTokens) * uint32(ch.rewardUnits);
                reason = 0;
            } else {
                reason = 4;
            }
        }
    }

    function claimReward(uint64 blockNumber, address miner, address recipient, uint256 solution) external whenNotPaused
        returns (uint32 rewardUnits, uint8 reason, bool premium, uint16 claimsCnt)
    {
        uint16 rewardsCnt;

        (rewardUnits, reason, premium, rewardsCnt, claimsCnt) = verifyClaim(blockNumber, miner, recipient, solution);

        if(reason == 0) {
            // Extra check that we don't have some unexpected leak
            require(rewardUnits > 0, "Invalid reward amount");
            require(rewardUnits <= uint256(2000).mul(REWARD_UNITS_STANDARD), "Invalid reward, amount too big");

            // Transfer reward to msg.sender
            uint256 rewardAmount = uint256(rewardUnits).mul(REWARD_UNIT);

            uint8 commisionPrc = records.getCommision(recipient);
            if(miner != recipient) {
                uint256 commisionAmount = rewardAmount.mul(commisionPrc).div(100);
                uint256 recipientAmount = rewardAmount.sub(commisionAmount);
                token.transfer(recipient, recipientAmount);
                token.transfer(miner, commisionAmount);
                emit Claim(blockNumber, recipient, miner, solution, commisionPrc, claimsCnt);
            } else {
                token.transfer(recipient, rewardAmount);
                emit Claim(blockNumber, recipient, miner, solution, 0, claimsCnt);
            }

            _claimedTokens = _claimedTokens.add(rewardAmount);

            // Extra check that we don't have some unexpected leak
            require(claimsCnt < REWARDS_CNT_LIMIT, "claim count is too big");
            require(claimsCnt < rewardsCnt, "claim count is too big");
            claimsCnt++;
            records._addClaim(blockNumber, recipient, rewardUnits);

            if(claimsCnt >= rewardsCnt) {
                _claimedChallenges++;
                admin._cleanupChallenge(blockNumber, premium);
            }

            // Notify the marketing contract
            if(marketingAddr != address(0)) {
                ILuminaMarketing marketing = ILuminaMarketing(marketingAddr);
                try marketing._claim(blockNumber, miner, recipient, rewardUnits, commisionPrc) {
                } catch Error(string memory message) {
                    _marketingCallSuccessCnt++;
                    emit MarketingCallFailed(marketingAddr, blockNumber, message);
                } catch {
                    _marketingCallFailedCnt++;
                    emit MarketingCallFailed(marketingAddr, blockNumber, "");
                }
            }
        }
    }

}
