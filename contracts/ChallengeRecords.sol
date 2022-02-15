// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./Parameters.sol";
import "./Utils.sol";

abstract contract ChallengeRecords is Parameters {

    struct Challenge {
        uint256 challengeHash;
        uint64 blockNumber;
        uint16 rewardUnits; // 1 - 1000
        uint8 index;
        bool valid;
        uint8 prev;
        uint8 next;
    }

    struct ChallengeSet {
        Challenge[MAX_CHALLENGE_CNT] ch;
        uint8 cnt;
        uint8 freeIndex;
        uint8 head;
        uint8 tail;
    }

    function _challengeSetInit(ChallengeSet storage chs) internal {

        require(CHALLENGE_NULL < 256, "ChallengeRecords: Invalid configuration: CHALLENGE_NULL");
        require(MAX_CHALLENGE_CNT <= CHALLENGE_NULL, "ChallengeRecords: Invalid configuration: MAX_CHALLENGE_CNT");

        for(uint8 i = 0; i < MAX_CHALLENGE_CNT; i++) {
            Challenge storage ch = chs.ch[i];
            ch.challengeHash = 0;
            ch.blockNumber = 0;
            ch.rewardUnits = 0;
            ch.index = i;
            ch.valid = false;
            ch.prev = CHALLENGE_NULL;
            ch.next = i+1 < MAX_CHALLENGE_CNT ? i+1 : CHALLENGE_NULL;
        }

        chs.cnt = 0;
        chs.freeIndex = 0;
        chs.head = CHALLENGE_NULL;
        chs.tail = CHALLENGE_NULL;
    }

    // Returns CHALLENGE_NULL  if not found
    function _challengeFind(ChallengeSet storage chs, uint64 blockNumber) internal view returns (uint8 index, uint8 generalDifficulty) {
        uint8 cnt = chs.cnt;
        require(cnt <= MAX_CHALLENGE_CNT, "ChallengeRecords: Invalid configuration: cnt <= MAX_CHALLENGE_CNT failed");
        index = chs.head;
        generalDifficulty = 0;
        for(uint8 i = 0; i < cnt; i++) {
            Challenge memory ch = _challengeGet(chs, index);

            if(ch.blockNumber == blockNumber) {
                require(index == ch.index, "ChallengeRecords._challengeFind(): corrupt list");
                generalDifficulty = MAX_CHALLENGE_DIFFICULTY - CHALLENGE_DIFFICULTY_STEP * (cnt - i - 1);
                require(MIN_CHALLENGE_DIFFICULTY <= generalDifficulty && generalDifficulty <= MAX_CHALLENGE_DIFFICULTY, "ChallengeRecords._challengeFind(): generalDifficulty out of range");
                return (index, generalDifficulty);
            }

            index = ch.next;
        }
        require(index == CHALLENGE_NULL, "ChallengeRecords._challengeFind(): corrupt list");
    }

    function _challengeGet(ChallengeSet storage chs, uint8 index) internal view returns (Challenge storage) {
        require(index < MAX_CHALLENGE_CNT, "ChallengeRecords._challengeGet(): index is out of range");

        Challenge storage ch = chs.ch[index];
        require(ch.index == index, "ChallengeRecords: corrupt challenge index");

        return ch;
    }

    function _challengesGet(ChallengeSet storage chs, uint8 limit)
    internal view returns (uint8 totalCnt, uint8[] memory indexes, uint64[] memory blockNumbers, uint16[] memory rewardUnits, uint256[] memory challengeHashes, uint8[] memory nexts) {
        uint8 cnt = limit < chs.cnt ? limit : chs.cnt;
        totalCnt = chs.cnt;
        indexes = new uint8[](cnt);
        blockNumbers = new uint64[](cnt);
        challengeHashes = new uint256[](cnt);
        nexts = new uint8[](cnt);
        rewardUnits = new uint16[](cnt);
        uint8 index = chs.head;
        for(uint8 i = 0; i < cnt; i++) {
            Challenge memory ch = _challengeGet(chs, index);
            indexes[i] = ch.index;
            blockNumbers[i] = ch.blockNumber;
            rewardUnits[i] = ch.rewardUnits;
            challengeHashes[i] = ch.challengeHash;
            nexts[i] = ch.next;
            index = ch.next;
        }
        require(limit < chs.cnt || index == CHALLENGE_NULL, "ChallengeRecords._challengesGet(): corrupt list");
    }

    function _challengeSetIsFull(ChallengeSet storage chs) internal view returns (bool) {
        return chs.cnt >= MAX_CHALLENGE_CNT;
    }

    function _challengeSetIsEmpty(ChallengeSet storage chs) internal view returns (bool) {
        return chs.cnt == 0;
    }

    function _challengeGetFirstBlock(ChallengeSet storage chs) internal view returns (uint64 blockNumber) {
        uint8 index = chs.head;
        if(index == CHALLENGE_NULL) {
            blockNumber = uint64(block.number);
        } else {
            Challenge memory ch = _challengeGet(chs, index);
            require(ch.valid, "ChallengeRecords: corrupt challenge item in the list");
            blockNumber = ch.blockNumber;
        }
    }

    function _challengeInsertHead(ChallengeSet storage chs, uint64 blockNumber, uint256 challengeHash, uint16 rewardUnits) internal {
        require(!_challengeSetIsFull(chs), "ChallengeRecords: Challenge set is full");

        uint8 index = chs.freeIndex;
        require(index < MAX_CHALLENGE_CNT, "ChallengeRecords: corrupt freeIndex");
        Challenge storage ch = _challengeGet(chs, index);
        require(!ch.valid, "ChallengeRecords: corrupt challenge item in freeList");
        chs.freeIndex = ch.next;

        ch.challengeHash = challengeHash;
        ch.blockNumber = blockNumber;
        ch.rewardUnits = rewardUnits;
        ch.valid = true;
        ch.prev = CHALLENGE_NULL;
        ch.next = chs.head;
        if(chs.head != CHALLENGE_NULL) {
            Challenge storage head = _challengeGet(chs, chs.head);
            head.prev = index;
        }
        chs.head = index;
        if(chs.tail == CHALLENGE_NULL) {
            chs.tail = index;
        }
        chs.cnt++;
    }

    function _challengeInsertTail(ChallengeSet storage chs, uint64 blockNumber, uint256 challengeHash, uint16 rewardUnits) internal {
        require(!_challengeSetIsFull(chs), "ChallengeRecords: Challenge set is full");

        uint8 index = chs.freeIndex;
        require(index < MAX_CHALLENGE_CNT, "ChallengeRecords: corrupt freeIndex");
        Challenge storage ch = _challengeGet(chs, index);
        require(!ch.valid, "ChallengeRecords: corrupt challenge item in freeList");
        chs.freeIndex = ch.next;

        ch.challengeHash = challengeHash;
        ch.blockNumber = blockNumber;
        ch.rewardUnits = rewardUnits;
        ch.valid = true;
        ch.prev = chs.tail;
        ch.next = CHALLENGE_NULL;
        if(chs.tail != CHALLENGE_NULL) {
            Challenge storage tail = _challengeGet(chs, chs.tail);
            tail.next = index;
        }
        chs.tail = index;
        if(chs.head == CHALLENGE_NULL) {
            chs.head = index;
        }
        chs.cnt++;
    }

    function _challengeRemove(ChallengeSet storage chs, uint8 index) internal {
        require(!_challengeSetIsEmpty(chs), "ChallengeRecords: Challenge set is empty");

        Challenge storage ch = _challengeGet(chs, index);
        require(ch.valid, "ChallengeRecords: removing invalid item");

        // Reconnect the double linked list
        if(ch.prev != CHALLENGE_NULL) {
            Challenge storage prev = _challengeGet(chs, ch.prev);
            prev.next = ch.next;
        }
        if(ch.next != CHALLENGE_NULL) {
            Challenge storage next = _challengeGet(chs, ch.next);
            next.prev = ch.prev;
        }

        if(index == chs.head) {
            chs.head = ch.next;
        }

        if(index == chs.tail) {
            chs.tail = ch.prev;
        }

        // Put the removed item back into the free list
        uint8 freeIndex = chs.freeIndex;
        require(freeIndex < MAX_CHALLENGE_CNT || freeIndex == CHALLENGE_NULL, "ChallengeRecords: corrupt freeIndex");
        ch.challengeHash = 0;
        ch.blockNumber = 0;
        ch.rewardUnits = 0;
        ch.valid = false;
        ch.prev = CHALLENGE_NULL;
        ch.next = freeIndex;
        chs.freeIndex = index;
        chs.cnt--;
    }

}
