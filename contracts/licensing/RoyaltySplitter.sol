// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title RoyaltySplitter
 * @notice Distributes royalties to multiple beneficiaries
 * @dev Simple pull-pattern splitter for license fees
 */
contract RoyaltySplitter is Ownable, ReentrancyGuard {
    struct Beneficiary {
        address account;
        uint16 shareBps; // Basis points (10000 = 100%)
    }
    
    Beneficiary[] public beneficiaries;
    mapping(address => uint256) public pendingWithdrawals;
    
    uint256 public totalShares;
    uint256 public totalReceived;
    uint256 public totalDistributed;
    
    event BeneficiaryAdded(address indexed account, uint16 shareBps);
    event BeneficiaryRemoved(address indexed account);
    event FundsReceived(address indexed from, uint256 amount);
    event FundsDistributed(uint256 amount);
    event Withdrawn(address indexed beneficiary, uint256 amount);
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @notice Add beneficiary with share percentage
     * @param account Beneficiary address
     * @param shareBps Share in basis points (100 = 1%)
     */
    function addBeneficiary(address account, uint16 shareBps) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(shareBps > 0, "Invalid share");
        require(totalShares + shareBps <= 10000, "Exceeds 100%");
        
        beneficiaries.push(Beneficiary({
            account: account,
            shareBps: shareBps
        }));
        
        totalShares += shareBps;
        emit BeneficiaryAdded(account, shareBps);
    }
    
    /**
     * @notice Remove beneficiary (sets share to 0)
     * @param index Beneficiary index
     */
    function removeBeneficiary(uint256 index) external onlyOwner {
        require(index < beneficiaries.length, "Invalid index");
        
        address account = beneficiaries[index].account;
        uint16 shareBps = beneficiaries[index].shareBps;
        
        totalShares -= shareBps;
        
        // Remove by swapping with last and popping
        beneficiaries[index] = beneficiaries[beneficiaries.length - 1];
        beneficiaries.pop();
        
        emit BeneficiaryRemoved(account);
    }
    
    /**
     * @notice Distribute received funds to beneficiaries
     */
    function distribute() public nonReentrant {
        uint256 balance = address(this).balance;
        uint256 toDistribute = balance - (totalReceived - totalDistributed);
        
        if (toDistribute == 0) return;
        
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            uint256 share = (toDistribute * beneficiaries[i].shareBps) / 10000;
            pendingWithdrawals[beneficiaries[i].account] += share;
        }
        
        totalDistributed += toDistribute;
        emit FundsDistributed(toDistribute);
    }
    
    /**
     * @notice Withdraw pending funds (pull pattern)
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds");
        
        pendingWithdrawals[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @notice Get number of beneficiaries
     * @return Count
     */
    function getBeneficiaryCount() external view returns (uint256) {
        return beneficiaries.length;
    }
    
    /**
     * @notice Receive funds and auto-distribute
     */
    receive() external payable {
        totalReceived += msg.value;
        emit FundsReceived(msg.sender, msg.value);
        distribute();
    }
}
