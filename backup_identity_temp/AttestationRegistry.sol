// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title AttestationRegistry
 * @notice Registry for verifiable credentials and attestations in the UNY-ID system
 * @dev Stores credential hashes, validates issuers, enforces expiry, and supports revocation
 * 
 * Features:
 * - Schema-based credential types (KYC, FACILITY, DEVICE, ENERGY_OUTPUT, etc.)
 * - Multi-issuer support with role-based permissions
 * - Expiry and freshness validation
 * - Revocation with reason tracking
 * - Selective disclosure support (only hashes stored on-chain)
 * - Batch operations for efficiency
 */
contract AttestationRegistry is AccessControl {
    using ECDSA for bytes32;

    // ============ Roles ============
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant KYC_ISSUER_ROLE = keccak256("KYC_ISSUER_ROLE");
    bytes32 public constant FACILITY_ISSUER_ROLE = keccak256("FACILITY_ISSUER_ROLE");
    bytes32 public constant DEVICE_ISSUER_ROLE = keccak256("DEVICE_ISSUER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant MRV_ORACLE_ROLE = keccak256("MRV_ORACLE_ROLE");

    // ============ Structs ============

    struct Attestation {
        address issuer;            // Who issued this credential
        address subject;           // Who/what this credential is about
        string schemaId;           // Credential schema (e.g., "SCHEMA/KYC_ORG_v1")
        bytes32 dataHash;          // Keccak256 of credential data (privacy-preserving)
        uint256 issuedAt;          // Timestamp
        uint256 validUntil;        // Expiry (0 = no expiry)
        bool revoked;              // Revocation flag
        string revocationReason;   // Why revoked
        bytes32 evidenceHash;      // Optional: supporting documents hash
    }

    struct Schema {
        string name;               // Schema name
        string description;        // Schema description
        uint256 defaultValidityDays; // Default validity period
        bool active;               // Schema active flag
        bytes32 jsonSchemaHash;    // Hash of JSON schema definition
    }

    // ============ State ============

    // attestationId => Attestation
    mapping(bytes32 => Attestation) public attestations;

    // subject => schemaId => attestationIds[]
    mapping(address => mapping(string => bytes32[])) public subjectAttestations;

    // schemaId => Schema
    mapping(string => Schema) public schemas;

    // schemaId => issuer => authorized
    mapping(string => mapping(address => bool)) public schemaIssuers;

    // Global counter for attestation IDs
    uint256 private _attestationCounter;

    // ============ Events ============

    event AttestationRecorded(
        bytes32 indexed attestationId,
        address indexed issuer,
        address indexed subject,
        string schemaId,
        bytes32 dataHash,
        uint256 validUntil
    );

    event AttestationRevoked(
        bytes32 indexed attestationId,
        address indexed revoker,
        string reason
    );

    event SchemaRegistered(
        string indexed schemaId,
        string name,
        uint256 defaultValidityDays
    );

    event SchemaIssuerAuthorized(
        string indexed schemaId,
        address indexed issuer
    );

    event SchemaIssuerRevoked(
        string indexed schemaId,
        address indexed issuer
    );

    // ============ Constructor ============

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        // Register default schemas
        _registerDefaultSchemas();
    }

    // ============ Core Functions ============

    /**
     * @notice Record a new attestation
     * @param subject Address of the credential subject
     * @param schemaId Schema identifier
     * @param dataHash Keccak256 hash of credential data
     * @param validUntil Expiry timestamp (0 = no expiry)
     * @param evidenceHash Optional supporting evidence hash
     * @return attestationId Unique attestation identifier
     */
    function record(
        address subject,
        string calldata schemaId,
        bytes32 dataHash,
        uint256 validUntil,
        bytes32 evidenceHash
    ) external returns (bytes32) {
        require(subject != address(0), "Invalid subject");
        require(bytes(schemaId).length > 0, "Schema ID required");
        require(schemas[schemaId].active, "Schema not active");
        require(
            hasRole(ISSUER_ROLE, msg.sender) || schemaIssuers[schemaId][msg.sender],
            "Not authorized for this schema"
        );

        _attestationCounter++;
        bytes32 attestationId = keccak256(
            abi.encodePacked(subject, schemaId, dataHash, _attestationCounter)
        );

        attestations[attestationId] = Attestation({
            issuer: msg.sender,
            subject: subject,
            schemaId: schemaId,
            dataHash: dataHash,
            issuedAt: block.timestamp,
            validUntil: validUntil,
            revoked: false,
            revocationReason: "",
            evidenceHash: evidenceHash
        });

        subjectAttestations[subject][schemaId].push(attestationId);

        emit AttestationRecorded(
            attestationId,
            msg.sender,
            subject,
            schemaId,
            dataHash,
            validUntil
        );

        return attestationId;
    }

    /**
     * @notice Record multiple attestations in one transaction
     * @param subjects Array of subject addresses
     * @param schemaIds Array of schema IDs
     * @param dataHashes Array of data hashes
     * @param validUntils Array of expiry timestamps
     * @return attestationIds Array of attestation IDs
     */
    function recordBatch(
        address[] calldata subjects,
        string[] calldata schemaIds,
        bytes32[] calldata dataHashes,
        uint256[] calldata validUntils
    ) external returns (bytes32[] memory) {
        require(
            subjects.length == schemaIds.length &&
            schemaIds.length == dataHashes.length &&
            dataHashes.length == validUntils.length,
            "Array length mismatch"
        );

        bytes32[] memory attestationIds = new bytes32[](subjects.length);

        for (uint256 i = 0; i < subjects.length; i++) {
            attestationIds[i] = this.record(
                subjects[i],
                schemaIds[i],
                dataHashes[i],
                validUntils[i],
                bytes32(0) // No evidence hash in batch
            );
        }

        return attestationIds;
    }

    /**
     * @notice Revoke an attestation
     * @param attestationId Attestation to revoke
     * @param reason Revocation reason
     */
    function revoke(bytes32 attestationId, string calldata reason) external {
        Attestation storage attestation = attestations[attestationId];
        require(attestation.issuedAt > 0, "Attestation does not exist");
        require(!attestation.revoked, "Already revoked");
        require(
            attestation.issuer == msg.sender || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized to revoke"
        );

        attestation.revoked = true;
        attestation.revocationReason = reason;

        emit AttestationRevoked(attestationId, msg.sender, reason);
    }

    // ============ Validation Functions ============

    /**
     * @notice Check if a subject has a valid attestation for a schema
     * @param subject Subject address
     * @param schemaId Schema identifier
     * @return valid True if valid attestation exists
     */
    function isValid(address subject, string calldata schemaId) external view returns (bool) {
        bytes32[] memory attestationIds = subjectAttestations[subject][schemaId];
        
        if (attestationIds.length == 0) return false;

        // Check most recent attestation (last in array)
        for (uint256 i = attestationIds.length; i > 0; i--) {
            bytes32 attestationId = attestationIds[i - 1];
            Attestation memory attestation = attestations[attestationId];

            if (attestation.revoked) continue;
            if (attestation.validUntil > 0 && block.timestamp > attestation.validUntil) continue;

            return true; // Found valid attestation
        }

        return false;
    }

    /**
     * @notice Check if attestation is still valid (not revoked, not expired)
     * @param attestationId Attestation identifier
     * @return valid True if valid
     */
    function isAttestationValid(bytes32 attestationId) public view returns (bool) {
        Attestation memory attestation = attestations[attestationId];
        
        if (attestation.issuedAt == 0) return false; // Doesn't exist
        if (attestation.revoked) return false;
        if (attestation.validUntil > 0 && block.timestamp > attestation.validUntil) return false;

        return true;
    }

    /**
     * @notice Check if attestation is fresh (issued within N days)
     * @param attestationId Attestation identifier
     * @param freshnessDays Maximum age in days
     * @return fresh True if fresh
     */
    function isFresh(bytes32 attestationId, uint256 freshnessDays) external view returns (bool) {
        if (!isAttestationValid(attestationId)) return false;

        Attestation memory attestation = attestations[attestationId];
        uint256 freshnessSeconds = freshnessDays * 1 days;

        return (block.timestamp - attestation.issuedAt) <= freshnessSeconds;
    }

    /**
     * @notice Get all attestations for a subject and schema
     * @param subject Subject address
     * @param schemaId Schema identifier
     * @return attestationIds Array of attestation IDs
     */
    function getAttestations(
        address subject,
        string calldata schemaId
    ) external view returns (bytes32[] memory) {
        return subjectAttestations[subject][schemaId];
    }

    /**
     * @notice Get the most recent valid attestation for a subject+schema
     * @param subject Subject address
     * @param schemaId Schema identifier
     * @return attestationId Most recent valid attestation (or bytes32(0) if none)
     */
    function getLatestValid(
        address subject,
        string calldata schemaId
    ) external view returns (bytes32) {
        bytes32[] memory attestationIds = subjectAttestations[subject][schemaId];
        
        if (attestationIds.length == 0) return bytes32(0);

        // Iterate backwards (most recent first)
        for (uint256 i = attestationIds.length; i > 0; i--) {
            bytes32 attestationId = attestationIds[i - 1];
            if (isAttestationValid(attestationId)) {
                return attestationId;
            }
        }

        return bytes32(0);
    }

    // ============ Schema Management ============

    /**
     * @notice Register a new credential schema
     * @param schemaId Unique schema identifier
     * @param name Human-readable name
     * @param description Schema description
     * @param defaultValidityDays Default validity period in days (0 = no expiry)
     * @param jsonSchemaHash Hash of the JSON schema definition
     */
    function registerSchema(
        string calldata schemaId,
        string calldata name,
        string calldata description,
        uint256 defaultValidityDays,
        bytes32 jsonSchemaHash
    ) external onlyRole(ADMIN_ROLE) {
        require(bytes(schemaId).length > 0, "Schema ID required");
        require(!schemas[schemaId].active, "Schema already exists");

        schemas[schemaId] = Schema({
            name: name,
            description: description,
            defaultValidityDays: defaultValidityDays,
            active: true,
            jsonSchemaHash: jsonSchemaHash
        });

        emit SchemaRegistered(schemaId, name, defaultValidityDays);
    }

    /**
     * @notice Authorize an issuer for a specific schema
     * @param schemaId Schema identifier
     * @param issuer Issuer address
     */
    function authorizeIssuer(
        string calldata schemaId,
        address issuer
    ) external onlyRole(ADMIN_ROLE) {
        require(schemas[schemaId].active, "Schema not active");
        require(issuer != address(0), "Invalid issuer");

        schemaIssuers[schemaId][issuer] = true;

        emit SchemaIssuerAuthorized(schemaId, issuer);
    }

    /**
     * @notice Revoke issuer authorization for a schema
     * @param schemaId Schema identifier
     * @param issuer Issuer address
     */
    function revokeIssuer(
        string calldata schemaId,
        address issuer
    ) external onlyRole(ADMIN_ROLE) {
        schemaIssuers[schemaId][issuer] = false;

        emit SchemaIssuerRevoked(schemaId, issuer);
    }

    // ============ Internal Functions ============

    /**
     * @dev Register default schemas on deployment
     */
    function _registerDefaultSchemas() private {
        // KYC Organization
        schemas["SCHEMA/KYC_ORG_v1"] = Schema({
            name: "KYC Organization",
            description: "Entity KYC/AML verification",
            defaultValidityDays: 365,
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // Sanctions Screening
        schemas["SCHEMA/SANCTIONS_SCREEN_v1"] = Schema({
            name: "Sanctions Screening",
            description: "OFAC/FATF sanctions and PEP screening",
            defaultValidityDays: 90,
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // Facility Credential
        schemas["SCHEMA/FACILITY_v1"] = Schema({
            name: "Facility Credential",
            description: "Physical facility verification (location, permits, capacity)",
            defaultValidityDays: 1825, // 5 years
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // Device/Meter
        schemas["SCHEMA/DEVICE_METER_v1"] = Schema({
            name: "Device Meter",
            description: "Smart meter or IoT device credential (calibration, firmware)",
            defaultValidityDays: 365,
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // Energy Output
        schemas["SCHEMA/ENERGY_OUTPUT_v1"] = Schema({
            name: "Energy Output",
            description: "MRV attestation for energy generation",
            defaultValidityDays: 0, // Perpetual record
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // REC Issuance
        schemas["SCHEMA/REC_ISSUANCE_v1"] = Schema({
            name: "REC Issuance",
            description: "Renewable Energy Certificate issuance record",
            defaultValidityDays: 0,
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // Carbon Credit
        schemas["SCHEMA/CARBON_CREDIT_v1"] = Schema({
            name: "Carbon Credit",
            description: "Carbon offset/removal credit verification",
            defaultValidityDays: 0,
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // Retirement
        schemas["SCHEMA/RETIREMENT_v1"] = Schema({
            name: "Retirement",
            description: "REC/Carbon credit retirement proof",
            defaultValidityDays: 0,
            active: true,
            jsonSchemaHash: bytes32(0)
        });

        // ESG Disclosure
        schemas["SCHEMA/ESG_DISCLOSURE_v1"] = Schema({
            name: "ESG Disclosure",
            description: "ESG reporting disclosure (ISSB/SASB compliant)",
            defaultValidityDays: 365,
            active: true,
            jsonSchemaHash: bytes32(0)
        });
    }
}
