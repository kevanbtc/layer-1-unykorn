// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AttestationRegistry.sol";

/**
 * @title ComplianceRegistry
 * @notice Policy enforcement for token classes with jurisdiction, KYC, and compliance rules
 * @dev Implements transfer hooks and dynamic compliance checks for RWAs and energy tokens
 * 
 * Features:
 * - Token class → required credential mappings
 * - Jurisdiction-based restrictions
 * - Transfer pre-flight checks
 * - Dynamic compliance states (paused, frozen, restricted)
 * - Whitelist/blacklist management
 * - Accredited investor verification
 * - Sanctions screening integration
 */
contract ComplianceRegistry is AccessControl {
    
    // ============ Roles ============
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant RULE_MANAGER_ROLE = keccak256("RULE_MANAGER_ROLE");

    // ============ Structs ============

    struct TokenClassRules {
        string[] requiredSchemas;      // Required credential schemas
        uint256 freshnessDays;         // Credential freshness requirement
        bool requiresAccreditation;    // Accredited investor only
        bool requiresSanctionsCheck;   // Sanctions screening required
        string[] allowedJurisdictions; // Allowed country codes (empty = all)
        string[] blockedJurisdictions; // Blocked country codes
        bool active;                   // Rules active
        uint256 minHoldingPeriod;      // Minimum holding time (seconds)
    }

    struct ComplianceProfile {
        bool sanctioned;               // On sanctions list
        bool frozen;                   // Account frozen
        string jurisdiction;           // Country code (ISO 3166-1 alpha-2)
        bool accredited;               // Accredited investor flag
        uint256 lastSanctionsCheck;    // Last sanctions screen timestamp
        bytes32[] requiredCredentials; // Pinned credential IDs
    }

    struct TransferRestriction {
        address token;                 // Token contract address
        uint256 tokenId;               // Token ID (0 for ERC20/fungible)
        address holder;                // Current holder
        uint256 acquiredAt;            // Acquisition timestamp
        uint256 releasesAt;            // When transfer is allowed
        string reason;                 // Restriction reason
    }

    // ============ State ============

    AttestationRegistry public attestationRegistry;

    // tokenClass => Rules
    mapping(bytes32 => TokenClassRules) public tokenClassRules;

    // address => ComplianceProfile
    mapping(address => ComplianceProfile) public profiles;

    // address => whitelisted
    mapping(address => bool) public whitelist;

    // address => blacklisted
    mapping(address => bool) public blacklist;

    // keccak256(token, tokenId, holder) => TransferRestriction
    mapping(bytes32 => TransferRestriction) public transferRestrictions;

    // Global pause
    bool public paused;

    // ============ Events ============

    event RulesUpdated(bytes32 indexed tokenClass, string[] requiredSchemas);
    event ProfileUpdated(address indexed account, string jurisdiction, bool accredited);
    event AccountFrozen(address indexed account, string reason);
    event AccountUnfrozen(address indexed account);
    event Whitelisted(address indexed account);
    event Blacklisted(address indexed account, string reason);
    event TransferRestricted(
        address indexed token,
        uint256 indexed tokenId,
        address indexed holder,
        uint256 releasesAt,
        string reason
    );
    event ComplianceCheckFailed(
        address indexed from,
        address indexed to,
        address indexed token,
        string reason
    );

    // ============ Constructor ============

    constructor(address _attestationRegistry) {
        require(_attestationRegistry != address(0), "Invalid attestation registry");
        
        attestationRegistry = AttestationRegistry(_attestationRegistry);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
        _grantRole(RULE_MANAGER_ROLE, msg.sender);
    }

    // ============ Rule Management ============

    /**
     * @notice Set compliance rules for a token class
     * @param tokenClass Keccak256 hash of token class identifier
     * @param requiredSchemas Array of required credential schema IDs
     * @param freshnessDays Credential freshness requirement in days
     * @param requiresAccreditation Accredited investor flag
     * @param requiresSanctionsCheck Sanctions screening flag
     * @param allowedJurisdictions Allowed country codes (empty = all)
     * @param blockedJurisdictions Blocked country codes
     * @param minHoldingPeriod Minimum holding period in seconds
     */
    function setRules(
        bytes32 tokenClass,
        string[] calldata requiredSchemas,
        uint256 freshnessDays,
        bool requiresAccreditation,
        bool requiresSanctionsCheck,
        string[] calldata allowedJurisdictions,
        string[] calldata blockedJurisdictions,
        uint256 minHoldingPeriod
    ) external onlyRole(RULE_MANAGER_ROLE) {
        tokenClassRules[tokenClass] = TokenClassRules({
            requiredSchemas: requiredSchemas,
            freshnessDays: freshnessDays,
            requiresAccreditation: requiresAccreditation,
            requiresSanctionsCheck: requiresSanctionsCheck,
            allowedJurisdictions: allowedJurisdictions,
            blockedJurisdictions: blockedJurisdictions,
            active: true,
            minHoldingPeriod: minHoldingPeriod
        });

        emit RulesUpdated(tokenClass, requiredSchemas);
    }

    /**
     * @notice Activate/deactivate rules for a token class
     * @param tokenClass Token class identifier
     * @param active Active flag
     */
    function setRulesActive(bytes32 tokenClass, bool active) 
        external 
        onlyRole(RULE_MANAGER_ROLE) 
    {
        tokenClassRules[tokenClass].active = active;
    }

    // ============ Profile Management ============

    /**
     * @notice Update compliance profile for an account
     * @param account Account address
     * @param jurisdiction Country code (ISO 3166-1 alpha-2)
     * @param accredited Accredited investor flag
     */
    function updateProfile(
        address account,
        string calldata jurisdiction,
        bool accredited
    ) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(account != address(0), "Invalid account");

        profiles[account].jurisdiction = jurisdiction;
        profiles[account].accredited = accredited;

        emit ProfileUpdated(account, jurisdiction, accredited);
    }

    /**
     * @notice Record sanctions screening result
     * @param account Account address
     * @param sanctioned Sanctioned flag
     */
    function updateSanctionsStatus(
        address account,
        bool sanctioned
    ) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        profiles[account].sanctioned = sanctioned;
        profiles[account].lastSanctionsCheck = block.timestamp;

        if (sanctioned) {
            blacklist[account] = true;
            emit Blacklisted(account, "Sanctions screening");
        }
    }

    /**
     * @notice Freeze an account
     * @param account Account address
     * @param reason Freeze reason
     */
    function freezeAccount(address account, string calldata reason) 
        external 
        onlyRole(COMPLIANCE_OFFICER_ROLE) 
    {
        profiles[account].frozen = true;
        emit AccountFrozen(account, reason);
    }

    /**
     * @notice Unfreeze an account
     * @param account Account address
     */
    function unfreezeAccount(address account) 
        external 
        onlyRole(COMPLIANCE_OFFICER_ROLE) 
    {
        profiles[account].frozen = false;
        emit AccountUnfrozen(account);
    }

    // ============ Whitelist/Blacklist ============

    /**
     * @notice Add address to whitelist
     * @param account Account address
     */
    function addToWhitelist(address account) 
        external 
        onlyRole(COMPLIANCE_OFFICER_ROLE) 
    {
        whitelist[account] = true;
        emit Whitelisted(account);
    }

    /**
     * @notice Add address to blacklist
     * @param account Account address
     * @param reason Blacklist reason
     */
    function addToBlacklist(address account, string calldata reason) 
        external 
        onlyRole(COMPLIANCE_OFFICER_ROLE) 
    {
        blacklist[account] = true;
        emit Blacklisted(account, reason);
    }

    /**
     * @notice Remove from blacklist
     * @param account Account address
     */
    function removeFromBlacklist(address account) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        blacklist[account] = false;
    }

    // ============ Transfer Restrictions ============

    /**
     * @notice Restrict transfers for a specific token holding
     * @param token Token contract address
     * @param tokenId Token ID (0 for fungible)
     * @param holder Current holder
     * @param releasesAt When restriction lifts (timestamp)
     * @param reason Restriction reason
     */
    function restrictTransfer(
        address token,
        uint256 tokenId,
        address holder,
        uint256 releasesAt,
        string calldata reason
    ) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        bytes32 restrictionId = keccak256(abi.encodePacked(token, tokenId, holder));

        transferRestrictions[restrictionId] = TransferRestriction({
            token: token,
            tokenId: tokenId,
            holder: holder,
            acquiredAt: block.timestamp,
            releasesAt: releasesAt,
            reason: reason
        });

        emit TransferRestricted(token, tokenId, holder, releasesAt, reason);
    }

    // ============ Compliance Checks ============

    /**
     * @notice Pre-transfer compliance check (called by token contracts)
     * @param tokenClass Token class identifier
     * @param from Sender address
     * @param to Recipient address
     * @param token Token contract address
     * @param tokenId Token ID (0 for fungible)
     * @return allowed True if transfer is compliant
     * @return reason Failure reason if not allowed
     */
    function preTransferCheck(
        bytes32 tokenClass,
        address from,
        address to,
        address token,
        uint256 tokenId
    ) external view returns (bool allowed, string memory reason) {
        // Global pause check
        if (paused) {
            return (false, "System paused");
        }

        // Blacklist check
        if (blacklist[from]) {
            return (false, "Sender blacklisted");
        }
        if (blacklist[to]) {
            return (false, "Recipient blacklisted");
        }

        // Frozen account check
        if (profiles[from].frozen) {
            return (false, "Sender account frozen");
        }
        if (profiles[to].frozen) {
            return (false, "Recipient account frozen");
        }

        // Sanctioned check
        if (profiles[from].sanctioned) {
            return (false, "Sender sanctioned");
        }
        if (profiles[to].sanctioned) {
            return (false, "Recipient sanctioned");
        }

        // Skip rule checks if no rules defined or inactive
        TokenClassRules memory rules = tokenClassRules[tokenClass];
        if (!rules.active) {
            return (true, "");
        }

        // Whitelist bypass
        if (whitelist[to]) {
            return (true, "");
        }

        // Transfer restriction check
        bytes32 restrictionId = keccak256(abi.encodePacked(token, tokenId, from));
        TransferRestriction memory restriction = transferRestrictions[restrictionId];
        if (restriction.releasesAt > 0 && block.timestamp < restriction.releasesAt) {
            return (false, string(abi.encodePacked("Transfer restricted: ", restriction.reason)));
        }

        // Minimum holding period check
        if (rules.minHoldingPeriod > 0 && restriction.acquiredAt > 0) {
            if (block.timestamp < restriction.acquiredAt + rules.minHoldingPeriod) {
                return (false, "Minimum holding period not met");
            }
        }

        // Jurisdiction check
        if (rules.allowedJurisdictions.length > 0) {
            bool jurisdictionAllowed = false;
            for (uint256 i = 0; i < rules.allowedJurisdictions.length; i++) {
                if (_stringsEqual(profiles[to].jurisdiction, rules.allowedJurisdictions[i])) {
                    jurisdictionAllowed = true;
                    break;
                }
            }
            if (!jurisdictionAllowed) {
                return (false, "Recipient jurisdiction not allowed");
            }
        }

        // Blocked jurisdiction check
        for (uint256 i = 0; i < rules.blockedJurisdictions.length; i++) {
            if (_stringsEqual(profiles[to].jurisdiction, rules.blockedJurisdictions[i])) {
                return (false, "Recipient jurisdiction blocked");
            }
        }

        // Accreditation check
        if (rules.requiresAccreditation && !profiles[to].accredited) {
            return (false, "Recipient not accredited");
        }

        // Sanctions check freshness
        if (rules.requiresSanctionsCheck) {
            uint256 daysSinceCheck = (block.timestamp - profiles[to].lastSanctionsCheck) / 1 days;
            if (daysSinceCheck > rules.freshnessDays) {
                return (false, "Sanctions screening expired");
            }
        }

        // Required credentials check
        for (uint256 i = 0; i < rules.requiredSchemas.length; i++) {
            if (!attestationRegistry.isValid(to, rules.requiredSchemas[i])) {
                return (false, string(abi.encodePacked("Missing credential: ", rules.requiredSchemas[i])));
            }

            // Freshness check
            if (rules.freshnessDays > 0) {
                bytes32 attestationId = attestationRegistry.getLatestValid(to, rules.requiredSchemas[i]);
                if (attestationId == bytes32(0)) {
                    return (false, "No valid credential found");
                }
                if (!attestationRegistry.isFresh(attestationId, rules.freshnessDays)) {
                    return (false, "Credential expired");
                }
            }
        }

        return (true, "");
    }

    /**
     * @notice Simplified check: is address compliant for a token class?
     * @param account Account address
     * @param tokenClass Token class identifier
     * @return compliant True if compliant
     */
    function isCompliant(address account, bytes32 tokenClass) 
        external 
        view 
        returns (bool) 
    {
        if (paused) return false;
        if (blacklist[account]) return false;
        if (profiles[account].frozen) return false;
        if (profiles[account].sanctioned) return false;

        TokenClassRules memory rules = tokenClassRules[tokenClass];
        if (!rules.active) return true;

        if (whitelist[account]) return true;

        // Check required credentials
        for (uint256 i = 0; i < rules.requiredSchemas.length; i++) {
            if (!attestationRegistry.isValid(account, rules.requiredSchemas[i])) {
                return false;
            }
        }

        return true;
    }

    // ============ Admin Functions ============

    /**
     * @notice Pause all compliance checks
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        paused = true;
    }

    /**
     * @notice Unpause compliance checks
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = false;
    }

    // ============ Helper Functions ============

    function _stringsEqual(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
