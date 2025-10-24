// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ComplianceOracle
 * @notice External compliance status oracle (sanctions, blacklists, entity verification)
 * @dev Supports multiple compliance sources and staleness checks
 */
contract ComplianceOracle is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    struct ComplianceStatus {
        bool sanctioned;      // OFAC/UN/EU sanctions
        bool verified;        // KYC/AML verified
        uint64 updatedAt;     // Last update timestamp
        bytes32 jurisdiction; // ISO country code
    }
    
    mapping(address => ComplianceStatus) public status;
    
    uint64 public stalenessThreshold = 30 days;
    
    event StatusUpdated(address indexed account, bool sanctioned, bool verified, bytes32 jurisdiction);
    event StalenessThresholdUpdated(uint64 newThreshold);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }
    
    /**
     * @notice Update compliance status for account
     * @param account Address to update
     * @param sanctioned True if sanctioned
     * @param verified True if KYC/AML verified
     * @param jurisdiction ISO country code
     */
    function updateStatus(
        address account,
        bool sanctioned,
        bool verified,
        bytes32 jurisdiction
    ) external onlyRole(ORACLE_ROLE) {
        status[account] = ComplianceStatus({
            sanctioned: sanctioned,
            verified: verified,
            updatedAt: uint64(block.timestamp),
            jurisdiction: jurisdiction
        });
        
        emit StatusUpdated(account, sanctioned, verified, jurisdiction);
    }
    
    /**
     * @notice Batch update compliance statuses
     * @param accounts Array of addresses
     * @param sanctioned Array of sanction flags
     * @param verified Array of verification flags
     * @param jurisdictions Array of jurisdictions
     */
    function batchUpdate(
        address[] calldata accounts,
        bool[] calldata sanctioned,
        bool[] calldata verified,
        bytes32[] calldata jurisdictions
    ) external onlyRole(ORACLE_ROLE) {
        require(
            accounts.length == sanctioned.length &&
            accounts.length == verified.length &&
            accounts.length == jurisdictions.length,
            "Array length mismatch"
        );
        
        uint64 timestamp = uint64(block.timestamp);
        
        for (uint256 i = 0; i < accounts.length; i++) {
            status[accounts[i]] = ComplianceStatus({
                sanctioned: sanctioned[i],
                verified: verified[i],
                updatedAt: timestamp,
                jurisdiction: jurisdictions[i]
            });
            
            emit StatusUpdated(accounts[i], sanctioned[i], verified[i], jurisdictions[i]);
        }
    }
    
    /**
     * @notice Check if account is compliant (not sanctioned + verified + not stale)
     * @param account Address to check
     * @return True if compliant
     */
    function isCompliant(address account) external view returns (bool) {
        ComplianceStatus memory s = status[account];
        
        // Check staleness
        if (block.timestamp - s.updatedAt > stalenessThreshold) {
            return false;
        }
        
        // Must be verified and not sanctioned
        return s.verified && !s.sanctioned;
    }
    
    /**
     * @notice Check sanctions status (ignores staleness)
     * @param account Address to check
     * @return True if sanctioned
     */
    function isSanctioned(address account) external view returns (bool) {
        return status[account].sanctioned;
    }
    
    /**
     * @notice Check verification status (ignores staleness)
     * @param account Address to check
     * @return True if verified
     */
    function isVerified(address account) external view returns (bool) {
        return status[account].verified;
    }
    
    /**
     * @notice Get full compliance status
     * @param account Address to check
     * @return Compliance status struct
     */
    function getStatus(address account) external view returns (ComplianceStatus memory) {
        return status[account];
    }
    
    /**
     * @notice Set staleness threshold
     * @param newThreshold New threshold in seconds
     */
    function setStalenessThreshold(uint64 newThreshold) external onlyRole(ADMIN_ROLE) {
        require(newThreshold > 0, "Invalid threshold");
        stalenessThreshold = newThreshold;
        emit StalenessThresholdUpdated(newThreshold);
    }
}
