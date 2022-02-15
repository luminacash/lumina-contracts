// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./ILuminaRecords.sol";
import "./Parameters.sol";
import "./OnlyToken.sol";
import "./OnlyTrustee.sol";
import "./OnlyAdmin.sol";

contract LuminaRecords is ILuminaRecords, Parameters, OnlyToken, OnlyTrustee, OnlyAdmin {

    uint8 private constant BALANCE_RECORDS_CNT = 5;
    uint8 private constant DEFAULT_COMMISION_PRC = 22;
    uint8 private constant ZERO_COMMISION_PRC = 255;
    uint8 private constant MIN_COMMISION_PRC = 10;
    uint8 private constant MAX_COMMISION_PRC = 90;

    struct AddrBalanceRecord {
        uint256 balance;
        uint64 blockNumber;
    }

    struct AddrBalanceRecords {
        AddrBalanceRecord[BALANCE_RECORDS_CNT] records;
        uint8 recordsCnt;
    }

    // Mapping blockNumber to Balance Records
    uint64 private _firstBlockNumber;
    mapping (address => AddrBalanceRecords) private _balanceRecords;

    // Mapping blockNumber to claimsCnt
    mapping (uint64 => uint16) private _claimsCnt;

    // Mapping blockNumber to address to uint32 (number of reward units)
    mapping (uint64 => mapping (address => uint32)) private _claimed;

    // Mapping wallet address to commision rate
    // Special internal encodings: 0 means default commision, 255 means no commision (0%)
    mapping (address => uint8) private _commisions;

    event Commision(address indexed wallet, uint8 commisionPrc);
    event RegisteredBalance(address indexed wallet, uint64 blockNumber, uint256 balance);

    constructor() {
        _firstBlockNumber = 0;
    }

    function getBalances() external view returns (uint256[] memory balances, uint64[] memory blockNumbers) {
        AddrBalanceRecords memory brs = _balanceRecords[msg.sender];
        uint8 cnt = brs.recordsCnt;
        balances = new uint256[](cnt);
        blockNumbers = new uint64[](cnt);
        for(uint8 i = 0; i < brs.recordsCnt; i++) {
            balances[i] = brs.records[i].balance;
            blockNumbers[i] = brs.records[i].blockNumber;
        }
    }

    function findBalance(address wallet, uint64 blockNumber) external view returns (uint256 balance) {
        balance = 0;

        AddrBalanceRecords memory brs = _balanceRecords[wallet];
        for(uint8 i = 0; i < brs.recordsCnt; i++) {
            if(blockNumber >= brs.records[i].blockNumber) {
                balance = brs.records[i].balance;
                return (balance);
            }
        }

        require(balance == 0, "_balanceFind: corrupt balance");
        return (balance);
    }

    function getClaimsCnt(uint64 blockNumber) public view returns (uint16) {
        return _claimsCnt[blockNumber];
    }

    function hasClaimed(uint64 blockNumber, address recipient) public view returns (uint32 rewardUnits) {
        rewardUnits = _claimed[blockNumber][recipient];
    }

    function getClaims(uint64[] memory blockNumbers, address recipient) external view returns (uint16[] memory claimsCnt, bool[] memory claimed) {
        uint8 cnt = uint8(blockNumbers.length);
        claimsCnt = new uint16[](cnt);
        claimed = new bool[](cnt);

        for(uint8 i = 0; i < cnt; i++) {
            claimsCnt[i] = getClaimsCnt(blockNumbers[i]);
            claimed[i] = hasClaimed(blockNumbers[i], recipient) != 0;
        }
    }

    function setCommision(uint8 commisionPrc) external {
        address wallet = msg.sender;
        require(commisionPrc == 0 || (MIN_COMMISION_PRC <= commisionPrc && commisionPrc <= MAX_COMMISION_PRC), "Commision value is out of allowed range: [10-90] or 0");
        uint8 c = commisionPrc == 0 ? ZERO_COMMISION_PRC : commisionPrc;
        _commisions[wallet] = c;
        emit Commision(wallet, commisionPrc);
    }

    function getCommision(address wallet) external view returns (uint8 commisionPrc) {
        uint8 c = _commisions[wallet];
        bool isContract = Address.isContract(wallet);
        // Contracts default commision is 0%, regular wallets defualt commision is 22%
        commisionPrc = c == 0 ? (isContract ? 0 : DEFAULT_COMMISION_PRC) : c == ZERO_COMMISION_PRC ? 0 : c;
        require(commisionPrc == 0 || (MIN_COMMISION_PRC <= commisionPrc && commisionPrc <= MAX_COMMISION_PRC), "Commision value is out of allowed range: [10-90] or 0");
    }

    function _cleanupBalances(AddrBalanceRecords storage brs) private {
        if(brs.recordsCnt > 1) {
            for(uint8 i = brs.recordsCnt-1; i > 0; i--) {
                AddrBalanceRecord storage br = brs.records[i-1];
                if(br.blockNumber <= _firstBlockNumber) {
                    // We can remove the last record
                    brs.recordsCnt--;
                }
            }
        }
    }

    function _registerBalance(address wallet, uint256 balance, bool force) external onlyToken returns (bool registered) {
        AddrBalanceRecords storage brs = _balanceRecords[wallet];
        _cleanupBalances(brs);
        if(balance < REWARD_UNIT) {
            // There is no sense if recording less than 0.001 LUMI, make it zero
            balance = 0;
            if(brs.recordsCnt == 0) {
                return false;
            }
        } else if(balance > MAX_REGISTERED_BALANCE) {
            balance = MAX_REGISTERED_BALANCE;
        }

        uint64 blockNumber = uint64(block.number);
        if(brs.recordsCnt > 0 && brs.records[0].balance == balance) {
            // Don't register the same amount again
            registered = true;
        } else if(brs.recordsCnt < BALANCE_RECORDS_CNT || force) {
            uint8 n = brs.recordsCnt < BALANCE_RECORDS_CNT ? brs.recordsCnt : BALANCE_RECORDS_CNT - 1;
            for(uint8 i = n; i > 0; i--) {
                brs.records[i] = brs.records[i-1];
            }
            brs.records[0].balance = balance;
            brs.records[0].blockNumber = blockNumber;
            if(brs.recordsCnt < BALANCE_RECORDS_CNT) {
                brs.recordsCnt++;
            }
            registered = true;
            emit RegisteredBalance(wallet, blockNumber, balance);
        } else {
            registered = false;
        }
    }

    function _updateBalance(address wallet, uint256 balance) external onlyToken {
        AddrBalanceRecords storage brs = _balanceRecords[wallet];
        _cleanupBalances(brs);
        if(balance < REWARD_UNIT) {
            // There is no sense if recording less than 0.001 LUMI, make it zero
            balance = 0;
            if(brs.recordsCnt == 0) {
                return;
            }
        } else if(balance > MAX_REGISTERED_BALANCE) {
            balance = MAX_REGISTERED_BALANCE;
        }

        uint64 blockNumber = uint64(block.number);
        if(brs.recordsCnt == 0) {
            brs.records[0].balance = balance;
            brs.records[0].blockNumber = blockNumber;
            brs.recordsCnt++;
            emit RegisteredBalance(wallet, blockNumber, balance);
        } else if(brs.records[0].balance > balance) {
            brs.records[0].balance = balance;
            blockNumber = brs.records[0].blockNumber;
            emit RegisteredBalance(wallet, blockNumber, balance);
        }
    }

    function _addClaim(uint64 blockNumber, address recipient, uint32 rewardUnits) external onlyTrustee {
        _claimsCnt[blockNumber]++;
        _claimed[blockNumber][recipient] = rewardUnits;
    }

    function _updateFirstBlockNumber(uint64 firstBlockNumber_) external onlyAdmin {
        _firstBlockNumber = firstBlockNumber_;
    }

}
