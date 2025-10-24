// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ComplianceRegistry
 * @notice Simplified compliance registry for energy system deployment
 * @dev Basic whitelist/blacklist/freeze functionality
 */
contract ComplianceRegistry is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER = keccak256("COMPLIANCE_OFFICER");
    
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public frozen;
    mapping(address => bool) public verified;
    
    bool public whitelistRequired = false;
    
    event Whitelisted(address indexed account);
    event Blacklisted(address indexed account);
    event Frozen(address indexed account);
    event Unfrozen(address indexed account);
    event Verified(address indexed account);
    event WhitelistRequirementToggled(bool required);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(COMPLIANCE_OFFICER, msg.sender);
    }
    
    /**
     * @notice Add address to whitelist
     * @param account Address to whitelist
     */
    function addToWhitelist(address account) external onlyRole(COMPLIANCE_OFFICER) {
        whitelist[account] = true;
        emit Whitelisted(account);
    }
    
    /**
     * @notice Add address to blacklist
     * @param account Address to blacklist
     */
    function addToBlacklist(address account) external onlyRole(COMPLIANCE_OFFICER) {
        blacklist[account] = true;
        emit Blacklisted(account);
    }
    
    /**
     * @notice Freeze account
     * @param account Address to freeze
     */
    function freeze(address account) external onlyRole(COMPLIANCE_OFFICER) {
        frozen[account] = true;
        emit Frozen(account);
    }
    
    /**
     * @notice Unfreeze account
     * @param account Address to unfreeze
     */
    function unfreeze(address account) external onlyRole(COMPLIANCE_OFFICER) {
        frozen[account] = false;
        emit Unfrozen(account);
    }
    
    /**
     * @notice Verify account (KYC/AML passed)
     * @param account Address to verify
     */
    function verify(address account) external onlyRole(COMPLIANCE_OFFICER) {
        verified[account] = true;
        emit Verified(account);
    }
    
    /**
     * @notice Toggle whitelist requirement
     * @param required True to require whitelist
     */
    function setWhitelistRequired(bool required) external onlyRole(ADMIN_ROLE) {
        whitelistRequired = required;
        emit WhitelistRequirementToggled(required);
    }
    
    /**
     * @notice Check if account is compliant
     * @param account Address to check
     * @return True if compliant
     */
    function isCompliant(address account) external view returns (bool) {
        if (blacklist[account]) return false;
        if (frozen[account]) return false;
        if (whitelistRequired && !whitelist[account]) return false;
        return true;
    }
    
    /**
     * @notice Check if account is verified (for T-REX compatibility)
     * @param account Address to check
     * @return True if verified
     */
    function isVerified(address account) external view returns (bool) {
        return verified[account];
    }
    
    /**
     * @notice Check if transfer is allowed (for T-REX compatibility)
     * @param from Source address
     * @param to Destination address
     * @param amount Amount (unused in basic version)
     * @return True if transfer allowed
     */
    function canTransfer(address from, address to, uint256 amount) external view returns (bool) {
        // Check blacklist
        if (blacklist[from] || blacklist[to]) return false;
        
        // Check frozen
        if (frozen[from] || frozen[to]) return false;
        
        // Check whitelist if required
        if (whitelistRequired) {
            if (!whitelist[from] || !whitelist[to]) return false;
        }
        
        return true;
    }
    
    /**
     * @notice Batch whitelist
     * @param accounts Array of addresses to whitelist
     */
    function batchWhitelist(address[] calldata accounts) external onlyRole(COMPLIANCE_OFFICER) {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
            emit Whitelisted(accounts[i]);
        }
    }
    
    /**
     * @notice Batch verify
     * @param accounts Array of addresses to verify
     */
    function batchVerify(address[] calldata accounts) external onlyRole(COMPLIANCE_OFFICER) {
        for (uint256 i = 0; i < accounts.length; i++) {
            verified[accounts[i]] = true;
            emit Verified(accounts[i]);
        }
    }
}
