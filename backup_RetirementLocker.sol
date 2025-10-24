// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../identity/AttestationRegistry.sol";

/**
 * @title RetirementLocker
 * @notice Retirement/redemption system for RECs and carbon credits with registry bridge
 * @dev Prevents double-counting across on-chain and off-chain registries
 * 
 * Features:
 * - Multi-registry support (Verra, Gold Standard, ACR, Puro, I-REC, GO)
 * - Anti-double-count protection (nonce-based serial tracking)
 * - Evidence anchoring (IPFS retirement certificates)
 * - Callback system for off-chain registry updates
 * - Attestation integration (retirement VCs)
 * - Beneficiary tracking (who retired for whom)
 * - Retirement certificates (NFT proof of retirement)
 */
contract RetirementLocker is AccessControl, ReentrancyGuard {
    
    // ============ Roles ============
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    // ============ Structs ============

    struct Retirement {
        uint256 retirementId;          // Unique retirement ID
        address token;                 // Token contract (ERC-1155)
        uint256 tokenId;               // Token ID
        uint256 amount;                // Amount retired
        address retirer;               // Who performed retirement
        address beneficiary;           // Who benefit is for
        uint256 timestamp;             // Retirement timestamp
        string[] serials;              // Serial numbers retired
        bytes32 evidenceHash;          // IPFS hash of retirement certificate
        string registry;               // External registry (Verra, GS, etc.)
        string registryRef;            // Registry reference ID
        bool bridged;                  // Bridged to external registry
        uint256 bridgedAt;             // Bridge timestamp
        string reason;                 // Retirement reason (offset, compliance, etc.)
    }

    struct RegistryBridge {
        string name;                   // Registry name
        string apiEndpoint;            // API endpoint
        address oracleAddress;         // Oracle for callbacks
        bool active;                   // Active flag
        uint256 totalRetirements;      // Total retirements bridged
        uint256 totalAmount;           // Total amount bridged
    }

    struct SerialNonce {
        string serial;                 // Serial number
        uint256 registryNonce;         // Registry-specific nonce
        bool retired;                  // Retired flag
        uint256 retiredAt;             // Retirement timestamp
        string retirementRef;          // Registry retirement reference
    }

    // ============ State ============

    AttestationRegistry public attestationRegistry;

    // Retirement counter
    uint256 private _retirementIdCounter;

    // retirementId => Retirement
    mapping(uint256 => Retirement) public retirements;

    // retirer => retirementIds[]
    mapping(address => uint256[]) public retirementsByRetirer;

    // beneficiary => retirementIds[]
    mapping(address => uint256[]) public retirementsByBeneficiary;

    // registry name => RegistryBridge
    mapping(string => RegistryBridge) public registryBridges;

    // keccak256(registry, serial) => SerialNonce
    mapping(bytes32 => SerialNonce) public serialNonces;

    // token => tokenId => totalRetired
    mapping(address => mapping(uint256 => uint256)) public totalRetired;

    // ============ Events ============

    event Retired(
        uint256 indexed retirementId,
        address indexed token,
        uint256 indexed tokenId,
        address retirer,
        address beneficiary,
        uint256 amount,
        string[] serials
    );

    event RetirementBridged(
        uint256 indexed retirementId,
        string indexed registry,
        string registryRef
    );

    event RegistryBridgeAdded(
        string indexed registry,
        string apiEndpoint,
        address oracleAddress
    );

    event SerialRetired(
        string indexed serial,
        string registry,
        uint256 nonce,
        string retirementRef
    );

    event RetirementCertificateIssued(
        uint256 indexed retirementId,
        bytes32 evidenceHash,
        bytes32 attestationId
    );

    // ============ Constructor ============

    constructor(address _attestationRegistry) {
        require(_attestationRegistry != address(0), "Invalid attestation registry");
        
        attestationRegistry = AttestationRegistry(_attestationRegistry);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(BRIDGE_ROLE, msg.sender);
    }

    // ============ Retirement Functions ============

    /**
     * @notice Retire (burn/lock) tokens
     * @param token Token contract address
     * @param tokenId Token ID
     * @param amount Amount to retire
     * @param beneficiary Beneficiary address (who benefit is for)
     * @param serials Serial numbers to retire
     * @param evidenceHash IPFS hash of retirement certificate
     * @param registry External registry name (empty if none)
     * @param reason Retirement reason
     * @return retirementId Unique retirement ID
     */
    function retire(
        address token,
        uint256 tokenId,
        uint256 amount,
        address beneficiary,
        string[] calldata serials,
        bytes32 evidenceHash,
        string calldata registry,
        string calldata reason
    ) external nonReentrant returns (uint256) {
        require(token != address(0), "Invalid token");
        require(amount > 0, "Invalid amount");
        require(beneficiary != address(0), "Invalid beneficiary");
        require(serials.length == amount, "Serial count mismatch");

        // Check balance
        require(
            IERC1155(token).balanceOf(msg.sender, tokenId) >= amount,
            "Insufficient balance"
        );

        // Check serials not already retired
        for (uint256 i = 0; i < serials.length; i++) {
            bytes32 serialKey = keccak256(abi.encodePacked(registry, serials[i]));
            require(!serialNonces[serialKey].retired, "Serial already retired");
        }

        // Transfer tokens to this contract (lock)
        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        // Create retirement record
        _retirementIdCounter++;
        uint256 retirementId = _retirementIdCounter;

        retirements[retirementId] = Retirement({
            retirementId: retirementId,
            token: token,
            tokenId: tokenId,
            amount: amount,
            retirer: msg.sender,
            beneficiary: beneficiary,
            timestamp: block.timestamp,
            serials: serials,
            evidenceHash: evidenceHash,
            registry: registry,
            registryRef: "",
            bridged: false,
            bridgedAt: 0,
            reason: reason
        });

        // Update indexes
        retirementsByRetirer[msg.sender].push(retirementId);
        retirementsByBeneficiary[beneficiary].push(retirementId);

        // Update totals
        totalRetired[token][tokenId] += amount;

        // Mark serials as retired
        for (uint256 i = 0; i < serials.length; i++) {
            bytes32 serialKey = keccak256(abi.encodePacked(registry, serials[i]));
            
            serialNonces[serialKey] = SerialNonce({
                serial: serials[i],
                registryNonce: registryBridges[registry].totalRetirements + i + 1,
                retired: true,
                retiredAt: block.timestamp,
                retirementRef: "" // Set later via bridge callback
            });

            emit SerialRetired(serials[i], registry, serialNonces[serialKey].registryNonce, "");
        }

        emit Retired(retirementId, token, tokenId, msg.sender, beneficiary, amount, serials);

        return retirementId;
    }

    /**
     * @notice Bridge retirement to external registry
     * @param retirementId Retirement ID
     * @param registryRef External registry reference ID
     */
    function bridgeRetirement(
        uint256 retirementId,
        string calldata registryRef
    ) external onlyRole(BRIDGE_ROLE) {
        Retirement storage retirement = retirements[retirementId];
        require(retirement.retirementId > 0, "Retirement not found");
        require(!retirement.bridged, "Already bridged");
        require(bytes(retirement.registry).length > 0, "No registry specified");
        require(registryBridges[retirement.registry].active, "Registry not active");

        retirement.bridged = true;
        retirement.bridgedAt = block.timestamp;
        retirement.registryRef = registryRef;

        // Update registry stats
        RegistryBridge storage bridge = registryBridges[retirement.registry];
        bridge.totalRetirements++;
        bridge.totalAmount += retirement.amount;

        // Update serial nonces with registry ref
        for (uint256 i = 0; i < retirement.serials.length; i++) {
            bytes32 serialKey = keccak256(abi.encodePacked(retirement.registry, retirement.serials[i]));
            serialNonces[serialKey].retirementRef = registryRef;
        }

        emit RetirementBridged(retirementId, retirement.registry, registryRef);
    }

    /**
     * @notice Issue retirement attestation (VC)
     * @param retirementId Retirement ID
     * @return attestationId Attestation ID from AttestationRegistry
     */
    function issueRetirementAttestation(uint256 retirementId) 
        external 
        onlyRole(OPERATOR_ROLE) 
        returns (bytes32) 
    {
        Retirement memory retirement = retirements[retirementId];
        require(retirement.retirementId > 0, "Retirement not found");

        // Create attestation data hash
        bytes32 dataHash = keccak256(abi.encodePacked(
            retirement.retirementId,
            retirement.token,
            retirement.tokenId,
            retirement.amount,
            retirement.retirer,
            retirement.beneficiary,
            retirement.timestamp,
            retirement.evidenceHash
        ));

        // Record attestation
        bytes32 attestationId = attestationRegistry.record(
            retirement.beneficiary,  // Subject
            "SCHEMA/RETIREMENT_v1",  // Schema
            dataHash,                // Data hash
            0,                       // No expiry (perpetual record)
            retirement.evidenceHash  // Evidence hash
        );

        emit RetirementCertificateIssued(retirementId, retirement.evidenceHash, attestationId);

        return attestationId;
    }

    // ============ Registry Bridge Management ============

    /**
     * @notice Add a registry bridge
     * @param name Registry name (Verra, GS, ACR, Puro, I-REC, GO, etc.)
     * @param apiEndpoint API endpoint
     * @param oracleAddress Oracle address for callbacks
     */
    function addRegistryBridge(
        string calldata name,
        string calldata apiEndpoint,
        address oracleAddress
    ) external onlyRole(ADMIN_ROLE) {
        require(bytes(name).length > 0, "Name required");
        require(!registryBridges[name].active, "Registry already exists");

        registryBridges[name] = RegistryBridge({
            name: name,
            apiEndpoint: apiEndpoint,
            oracleAddress: oracleAddress,
            active: true,
            totalRetirements: 0,
            totalAmount: 0
        });

        emit RegistryBridgeAdded(name, apiEndpoint, oracleAddress);
    }

    /**
     * @notice Deactivate a registry bridge
     * @param name Registry name
     */
    function deactivateRegistry(string calldata name) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        registryBridges[name].active = false;
    }

    // ============ View Functions ============

    /**
     * @notice Get retirement details
     * @param retirementId Retirement ID
     * @return retirement Retirement struct
     */
    function getRetirement(uint256 retirementId) external view returns (Retirement memory) {
        return retirements[retirementId];
    }

    /**
     * @notice Get retirements by retirer
     * @param retirer Retirer address
     * @return retirementIds Array of retirement IDs
     */
    function getRetirementsByRetirer(address retirer) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return retirementsByRetirer[retirer];
    }

    /**
     * @notice Get retirements by beneficiary
     * @param beneficiary Beneficiary address
     * @return retirementIds Array of retirement IDs
     */
    function getRetirementsByBeneficiary(address beneficiary) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return retirementsByBeneficiary[beneficiary];
    }

    /**
     * @notice Check if serial is retired
     * @param registry Registry name
     * @param serial Serial number
     * @return retired Retired flag
     */
    function isSerialRetired(string calldata registry, string calldata serial) 
        external 
        view 
        returns (bool) 
    {
        bytes32 serialKey = keccak256(abi.encodePacked(registry, serial));
        return serialNonces[serialKey].retired;
    }

    /**
     * @notice Get serial nonce
     * @param registry Registry name
     * @param serial Serial number
     * @return nonce SerialNonce struct
     */
    function getSerialNonce(string calldata registry, string calldata serial) 
        external 
        view 
        returns (SerialNonce memory) 
    {
        bytes32 serialKey = keccak256(abi.encodePacked(registry, serial));
        return serialNonces[serialKey];
    }

    /**
     * @notice Get total retired for token
     * @param token Token contract address
     * @param tokenId Token ID
     * @return amount Total retired amount
     */
    function getTotalRetired(address token, uint256 tokenId) 
        external 
        view 
        returns (uint256) 
    {
        return totalRetired[token][tokenId];
    }

    /**
     * @notice Get registry bridge info
     * @param name Registry name
     * @return bridge RegistryBridge struct
     */
    function getRegistryBridge(string calldata name) 
        external 
        view 
        returns (RegistryBridge memory) 
    {
        return registryBridges[name];
    }

    // ============ ERC1155 Receiver ============

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
