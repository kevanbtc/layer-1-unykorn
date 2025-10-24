// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title IdentityNFT
 * @notice Non-transferable identity NFT (Soulbound Token) with DID binding and ERC-6551 Token-Bound Account support
 * @dev Represents entities (person/company/facility/device) in the UNY-ID system
 * 
 * Features:
 * - Non-transferable by default (SBT) unless TRANSFER_ROLE granted
 * - W3C DID binding (did:unykorn:<hash>)
 * - ERC-6551 Token-Bound Account (TBA) integration
 * - Multi-tiered issuer roles (KYC, FACILITY, DEVICE, VERIFIER)
 * - Credential anchor hashes for verifiable credentials
 * - Revocation and expiry management
 */
contract IdentityNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // ============ Roles ============
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant KYC_ISSUER_ROLE = keccak256("KYC_ISSUER_ROLE");
    bytes32 public constant FACILITY_ISSUER_ROLE = keccak256("FACILITY_ISSUER_ROLE");
    bytes32 public constant DEVICE_ISSUER_ROLE = keccak256("DEVICE_ISSUER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE"); // Override non-transferability

    // ============ State ============
    Counters.Counter private _tokenIdCounter;

    struct Identity {
        string did;                    // W3C DID (e.g., did:unykorn:abc123)
        address tba;                   // ERC-6551 Token-Bound Account address
        string shortId;                // Human-readable ID (UNYID:US-ACME-PLANT01...)
        uint8 entityType;              // 0=Person, 1=Company, 2=Facility, 3=Device
        uint256 issuedAt;              // Timestamp
        uint256 expiresAt;             // 0 = no expiry
        bool revoked;                  // Revocation flag
        bytes32 metadataHash;          // IPFS hash of metadata
    }

    mapping(uint256 => Identity) public identities;
    mapping(string => uint256) public didToTokenId;      // DID → tokenId
    mapping(string => uint256) public shortIdToTokenId;  // shortId → tokenId
    mapping(uint256 => bytes32[]) public credentialHashes; // tokenId → credential anchor hashes

    // ============ Events ============
    event IdentityMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string did,
        string shortId,
        uint8 entityType
    );
    event DIDLinked(uint256 indexed tokenId, string did);
    event TBABound(uint256 indexed tokenId, address tba);
    event CredentialAnchored(uint256 indexed tokenId, bytes32 credentialHash, string schemaId);
    event IdentityRevoked(uint256 indexed tokenId, string reason);
    event IdentityExpired(uint256 indexed tokenId);

    // ============ Constructor ============
    constructor() ERC721("UNY Identity Passport", "UNYID") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    // ============ Core Functions ============

    /**
     * @notice Mint a new identity NFT (SBT)
     * @param to Owner address
     * @param did W3C DID string
     * @param shortId Human-readable ID
     * @param entityType 0=Person, 1=Company, 2=Facility, 3=Device
     * @param expiresAt Expiry timestamp (0 = no expiry)
     * @param metadataHash IPFS hash of metadata
     * @return tokenId Minted token ID
     */
    function mint(
        address to,
        string calldata did,
        string calldata shortId,
        uint8 entityType,
        uint256 expiresAt,
        bytes32 metadataHash
    ) external onlyRole(ISSUER_ROLE) returns (uint256) {
        require(to != address(0), "Cannot mint to zero address");
        require(bytes(did).length > 0, "DID required");
        require(didToTokenId[did] == 0, "DID already exists");
        require(bytes(shortId).length > 0, "ShortId required");
        require(shortIdToTokenId[shortId] == 0, "ShortId already exists");
        require(entityType <= 3, "Invalid entity type");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);

        identities[tokenId] = Identity({
            did: did,
            tba: address(0), // Set later via bindTBA
            shortId: shortId,
            entityType: entityType,
            issuedAt: block.timestamp,
            expiresAt: expiresAt,
            revoked: false,
            metadataHash: metadataHash
        });

        didToTokenId[did] = tokenId;
        shortIdToTokenId[shortId] = tokenId;

        emit IdentityMinted(tokenId, to, did, shortId, entityType);

        return tokenId;
    }

    /**
     * @notice Bind an ERC-6551 Token-Bound Account to this identity
     * @param tokenId Identity NFT token ID
     * @param tbaAddress The deployed TBA contract address
     */
    function bindTBA(uint256 tokenId, address tbaAddress) external onlyRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(tbaAddress != address(0), "Invalid TBA address");
        require(identities[tokenId].tba == address(0), "TBA already bound");

        identities[tokenId].tba = tbaAddress;

        emit TBABound(tokenId, tbaAddress);
    }

    /**
     * @notice Anchor a verifiable credential hash to this identity
     * @param tokenId Identity NFT token ID
     * @param credentialHash Keccak256 hash of the credential
     * @param schemaId Schema identifier (e.g., "SCHEMA/KYC_ORG_v1")
     */
    function anchorCredential(
        uint256 tokenId,
        bytes32 credentialHash,
        string calldata schemaId
    ) external {
        require(_exists(tokenId), "Token does not exist");
        require(
            hasRole(ISSUER_ROLE, msg.sender) || 
            hasRole(KYC_ISSUER_ROLE, msg.sender) ||
            hasRole(FACILITY_ISSUER_ROLE, msg.sender) ||
            hasRole(DEVICE_ISSUER_ROLE, msg.sender) ||
            hasRole(VERIFIER_ROLE, msg.sender),
            "Not authorized to anchor credentials"
        );

        credentialHashes[tokenId].push(credentialHash);

        emit CredentialAnchored(tokenId, credentialHash, schemaId);
    }

    /**
     * @notice Revoke an identity (mark as invalid)
     * @param tokenId Identity NFT token ID
     * @param reason Revocation reason
     */
    function revoke(uint256 tokenId, string calldata reason) external onlyRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(!identities[tokenId].revoked, "Already revoked");

        identities[tokenId].revoked = true;

        emit IdentityRevoked(tokenId, reason);
    }

    // ============ View Functions ============

    /**
     * @notice Check if an identity is valid (not revoked, not expired)
     * @param tokenId Identity NFT token ID
     * @return valid True if valid
     */
    function isValid(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) return false;

        Identity memory identity = identities[tokenId];
        
        if (identity.revoked) return false;
        if (identity.expiresAt > 0 && block.timestamp > identity.expiresAt) return false;

        return true;
    }

    /**
     * @notice Get identity by DID
     * @param did W3C DID string
     * @return tokenId Token ID (0 if not found)
     */
    function getByDID(string calldata did) external view returns (uint256) {
        return didToTokenId[did];
    }

    /**
     * @notice Get identity by short ID
     * @param shortId Human-readable short ID
     * @return tokenId Token ID (0 if not found)
     */
    function getByShortId(string calldata shortId) external view returns (uint256) {
        return shortIdToTokenId[shortId];
    }

    /**
     * @notice Get all credential hashes for an identity
     * @param tokenId Identity NFT token ID
     * @return hashes Array of credential hashes
     */
    function getCredentials(uint256 tokenId) external view returns (bytes32[] memory) {
        return credentialHashes[tokenId];
    }

    /**
     * @notice Get complete identity data
     * @param tokenId Identity NFT token ID
     * @return identity Full Identity struct
     */
    function getIdentity(uint256 tokenId) external view returns (Identity memory) {
        require(_exists(tokenId), "Token does not exist");
        return identities[tokenId];
    }

    // ============ Transfer Override (SBT Logic) ============

    /**
     * @dev Override transfers to make them non-transferable by default
     * Only accounts with TRANSFER_ROLE can transfer (for escrow/custody)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from == address(0))
        if (from == address(0)) {
            return;
        }

        // Allow burning (to == address(0))
        if (to == address(0)) {
            return;
        }

        // Otherwise, require TRANSFER_ROLE
        require(
            hasRole(TRANSFER_ROLE, msg.sender),
            "IdentityNFT: Non-transferable (SBT)"
        );
    }

    // ============ Interface Support ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ============ Token URI ============

    /**
     * @dev Return metadata URI for identity NFT
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        Identity memory identity = identities[tokenId];
        
        // Return IPFS hash as base58 string
        // In production, convert metadataHash to ipfs://CID format
        return string(abi.encodePacked("ipfs://", _bytes32ToBase58(identity.metadataHash)));
    }

    /**
     * @dev Helper to convert bytes32 to base58 (simplified for demo)
     * In production, use a proper base58 library
     */
    function _bytes32ToBase58(bytes32 hash) private pure returns (string memory) {
        // Placeholder: return hex string
        // TODO: Implement proper base58 encoding or use off-chain conversion
        return _toHexString(uint256(hash), 32);
    }

    function _toHexString(uint256 value, uint256 length) private pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
}
