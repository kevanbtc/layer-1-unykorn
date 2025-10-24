// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BufferPool
 * @notice Carbon credit buffer pool for reversals/permanence risk
 * @dev Holds percentage of issued credits as insurance
 */
contract BufferPool is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    
    struct PoolConfig {
        uint16 bufferPercent;  // Basis points (1500 = 15%)
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        bool active;
    }
    
    // Standard => Pool config
    mapping(bytes32 => PoolConfig) public pools;
    
    // Standard => Project => Buffered amount
    mapping(bytes32 => mapping(bytes32 => uint256)) public buffered;
    
    event PoolCreated(bytes32 indexed standard, uint16 bufferPercent);
    event Deposited(bytes32 indexed standard, bytes32 indexed projectId, uint256 amount);
    event Withdrawn(bytes32 indexed standard, bytes32 indexed projectId, uint256 amount, string reason);
    event BufferPercentUpdated(bytes32 indexed standard, uint16 newPercent);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }
    
    /**
     * @notice Create buffer pool for standard
     * @param standard Credit standard (e.g., "VERRA_VCS")
     * @param bufferPercent Buffer percentage in basis points (1500 = 15%)
     */
    function createPool(bytes32 standard, uint16 bufferPercent) external onlyRole(ADMIN_ROLE) {
        require(!pools[standard].active, "Pool exists");
        require(bufferPercent > 0 && bufferPercent <= 5000, "Invalid buffer percent");
        
        pools[standard] = PoolConfig({
            bufferPercent: bufferPercent,
            totalDeposits: 0,
            totalWithdrawals: 0,
            active: true
        });
        
        emit PoolCreated(standard, bufferPercent);
    }
    
    /**
     * @notice Calculate required buffer amount
     * @param standard Credit standard
     * @param issuanceAmount Issuance amount
     * @return Required buffer amount
     */
    function calculateBuffer(bytes32 standard, uint256 issuanceAmount) public view returns (uint256) {
        PoolConfig memory pool = pools[standard];
        require(pool.active, "Pool not active");
        
        return (issuanceAmount * pool.bufferPercent) / 10000;
    }
    
    /**
     * @notice Deposit credits to buffer pool
     * @param standard Credit standard
     * @param projectId Project identifier
     * @param amount Amount to buffer
     */
    function deposit(bytes32 standard, bytes32 projectId, uint256 amount)
        external
        onlyRole(MANAGER_ROLE)
        nonReentrant
    {
        require(pools[standard].active, "Pool not active");
        require(amount > 0, "Invalid amount");
        
        buffered[standard][projectId] += amount;
        pools[standard].totalDeposits += amount;
        
        emit Deposited(standard, projectId, amount);
    }
    
    /**
     * @notice Withdraw from buffer (reversal event)
     * @param standard Credit standard
     * @param projectId Project identifier
     * @param amount Amount to withdraw
     * @param reason Reason for withdrawal
     */
    function withdraw(bytes32 standard, bytes32 projectId, uint256 amount, string calldata reason)
        external
        onlyRole(MANAGER_ROLE)
        nonReentrant
    {
        require(buffered[standard][projectId] >= amount, "Insufficient buffer");
        
        buffered[standard][projectId] -= amount;
        pools[standard].totalWithdrawals += amount;
        
        emit Withdrawn(standard, projectId, amount, reason);
    }
    
    /**
     * @notice Update buffer percentage
     * @param standard Credit standard
     * @param newPercent New buffer percentage in basis points
     */
    function setBufferPercent(bytes32 standard, uint16 newPercent) external onlyRole(ADMIN_ROLE) {
        require(pools[standard].active, "Pool not active");
        require(newPercent > 0 && newPercent <= 5000, "Invalid percent");
        
        pools[standard].bufferPercent = newPercent;
        emit BufferPercentUpdated(standard, newPercent);
    }
    
    /**
     * @notice Get pool statistics
     * @param standard Credit standard
     * @return Pool configuration and totals
     */
    function getPoolStats(bytes32 standard)
        external
        view
        returns (
            uint16 bufferPercent,
            uint256 totalDeposits,
            uint256 totalWithdrawals,
            uint256 currentBalance,
            bool active
        )
    {
        PoolConfig memory pool = pools[standard];
        return (
            pool.bufferPercent,
            pool.totalDeposits,
            pool.totalWithdrawals,
            pool.totalDeposits - pool.totalWithdrawals,
            pool.active
        );
    }
}
