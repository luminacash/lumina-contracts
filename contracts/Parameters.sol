// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Parameters {
    // The DEMO mode limits rewards to 1 per challenge and limits blocks per challenge to 2
    bool public constant DEMO = true;

    // Number of decimals in reward token
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant TOKEN_UNIT = 10 ** TOKEN_DECIMALS; // 1 LUMI

    // The lucky number determines the premium challenges
    uint8 public constant LUCKY_NUMBER = 2;

    // Challenges
    uint8 public constant CHALLENGE_NULL = 255;
    uint8 public constant MAX_CHALLENGE_CNT = 100;
    uint8 public constant MIN_CHALLENGE_DIFFICULTY = DEMO ? 10 : 20;
    uint8 public constant MAX_CHALLENGE_DIFFICULTY = DEMO ? 208 : 218;
    uint8 public constant CHALLENGE_DIFFICULTY_STEP = 2;

    // Creating new challenges
    uint64 public constant BLOCKS_PER_DAY = 39272; // 3600*24 / 2.2

    uint64 public constant MAX_DONOR_BLOCKS = 200; // number of most recent consecutive blocks that can be used as donors

    // Number of blocks we need to wait for a new challenge
    uint8 public constant BLOCKS_PER_CHALLENGE = DEMO ? 2 : 100;

    // Hard limit on number of claims per challenge
    uint16 public constant REWARDS_CNT_LIMIT = DEMO ? 2 : 500;

    // Ramp-up in Newton Epoch
    uint256 public constant REWARD_UNIT = 10 ** (TOKEN_DECIMALS-3); // 0.001 LUMI
    uint16 public constant REWARD_UNITS_START = 10; // 0.01 LUMI
    uint16 public constant REWARD_UNITS_INC = 10; // 0.01 LUMI
    uint16 public constant REWARD_UNITS_STANDARD = 1000; // 1 LUMI
    uint16 public constant REWARD_INC_INTERVAL = DEMO ? 5 : 2700; // One increase per 2700 regular challenges, ~ add reward unit every week

    // external miners can only make claims on addresses with at least 0.01 LUMI
    uint256 public constant MINERS_CLAIM_MIN_RECIPIENT_BALANCE = 10 * REWARD_UNIT; // 0.01 LUMI

    uint256 public constant MAX_REGISTERED_BALANCE = 1000 * TOKEN_UNIT;

    // Cooldown in Einstein Epoch
    // Increase BLOCKS_PER_CHALLENGE by 2 blocks every week
    uint64 public constant BLOCKS_PER_CHALLENGE_INC = 2;
    uint64 public constant BLOCKS_PER_CHALLENGE_INC_INTERVAL = 1 * 7 * BLOCKS_PER_DAY;

}
