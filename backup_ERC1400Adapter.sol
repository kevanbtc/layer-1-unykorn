// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../compliance/ComplianceRegistry.sol";

/**
 * @title ERC1400Adapter
 * @notice Simplified ERC-1400-style partitioned security token for energy securities
 * @dev Compliance-gated regulated securities with partition support
 * 
 * Features:
 * - Partitions (tranches) for different investor classes (Reg D, Reg S, etc.)
 * - Controller-driven force transfer (for legal compliance)
 * - Transfer restrictions (lock-ups, whitelist)
 * - Document references (offering memos, amendments)
 * - Integration with ComplianceRegistry
 * 
 * Use cases:
 * - Energy project bonds/notes
 * - Green bonds
 * - Power purchase agreement (PPA) backed securities
 * - Renewable energy asset tokenization
 */
contract ERC1400Adapter is ERC20, AccessControl {
    
    // ============ Roles ============
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // ============ Structs ============

    struct Partition {
        string name;                   // Partition name (e.g., "RegD-US", "RegS-EU")
        bytes32 partitionId;           // Keccak256 hash of name
        uint256 totalSupply;           // Tokens in this partition
        bool locked;                   // Partition locked (no transfers)
        uint256 lockExpiry;            // When lock expires
        bytes32 complianceClass;       // ComplianceRegistry token class
    }

    struct Document {
        string name;                   // Document name
        string uri;                    // IPFS/HTTP URI
        bytes32 documentHash;          // Document hash
        uint256 timestamp;             // Upload timestamp
    }

    // ============ State ============

    ComplianceRegistry public complianceRegistry;

    // partitionId => Partition
    mapping(bytes32 => Partition) public partitions;

    // partitionId => holder => balance
    mapping(bytes32 => mapping(address => uint256)) public partitionBalances;

    // holder => partitionId => locked amount
    mapping(address => mapping(bytes32 => uint256)) public lockedBalances;

    // Document array
    Document[] public documents;

    // Whether token is controlled (allows force transfers)
    bool public isControllable;

    // ============ Events ============

    event PartitionCreated(bytes32 indexed partitionId, string name, bytes32 complianceClass);
    event IssuedByPartition(bytes32 indexed partitionId, address indexed to, uint256 amount);
    event RedeemedByPartition(bytes32 indexed partitionId, address indexed from, uint256 amount);
    event TransferByPartition(
        bytes32 indexed partitionId,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event ControllerTransfer(
        address indexed controller,
        address indexed from,
        address indexed to,
        uint256 amount,
        string reason
    );
    event DocumentPublished(uint256 indexed index, string name, string uri);
    event PartitionLocked(bytes32 indexed partitionId, uint256 lockExpiry);
    event PartitionUnlocked(bytes32 indexed partitionId);

    // ============ Constructor ============

    constructor(
        string memory name,
        string memory symbol,
        address _complianceRegistry,
        bool _isControllable
    ) ERC20(name, symbol) {
        require(_complianceRegistry != address(0), "Invalid compliance registry");
        
        complianceRegistry = ComplianceRegistry(_complianceRegistry);
        isControllable = _isControllable;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(CONTROLLER_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    // ============ Partition Management ============

    /**
     * @notice Create a new partition
     * @param name Partition name
     * @param complianceClass ComplianceRegistry token class
     * @return partitionId Partition identifier
     */
    function createPartition(
        string calldata name,
        bytes32 complianceClass
    ) external onlyRole(ISSUER_ROLE) returns (bytes32) {
        bytes32 partitionId = keccak256(abi.encodePacked(name));
        require(partitions[partitionId].partitionId == bytes32(0), "Partition exists");

        partitions[partitionId] = Partition({
            name: name,
            partitionId: partitionId,
            totalSupply: 0,
            locked: false,
            lockExpiry: 0,
            complianceClass: complianceClass
        });

        emit PartitionCreated(partitionId, name, complianceClass);

        return partitionId;
    }

    /**
     * @notice Lock a partition (prevent transfers)
     * @param partitionId Partition identifier
     * @param lockExpiry Lock expiry timestamp (0 = indefinite)
     */
    function lockPartition(bytes32 partitionId, uint256 lockExpiry) 
        external 
        onlyRole(CONTROLLER_ROLE) 
    {
        require(partitions[partitionId].partitionId != bytes32(0), "Partition not found");
        
        partitions[partitionId].locked = true;
        partitions[partitionId].lockExpiry = lockExpiry;

        emit PartitionLocked(partitionId, lockExpiry);
    }

    /**
     * @notice Unlock a partition
     * @param partitionId Partition identifier
     */
    function unlockPartition(bytes32 partitionId) 
        external 
        onlyRole(CONTROLLER_ROLE) 
    {
        require(partitions[partitionId].partitionId != bytes32(0), "Partition not found");
        
        partitions[partitionId].locked = false;
        partitions[partitionId].lockExpiry = 0;

        emit PartitionUnlocked(partitionId);
    }

    // ============ Issuance & Redemption ============

    /**
     * @notice Issue tokens to a partition
     * @param partitionId Partition identifier
     * @param to Recipient address
     * @param amount Amount to issue
     */
    function issueByPartition(
        bytes32 partitionId,
        address to,
        uint256 amount
    ) external onlyRole(ISSUER_ROLE) {
        require(to != address(0), "Invalid recipient");
        require(partitions[partitionId].partitionId != bytes32(0), "Partition not found");
        require(amount > 0, "Invalid amount");

        // Compliance check
        require(
            complianceRegistry.isCompliant(to, partitions[partitionId].complianceClass),
            "Recipient not compliant"
        );

        // Mint tokens
        _mint(to, amount);
        
        // Update partition balance
        partitionBalances[partitionId][to] += amount;
        partitions[partitionId].totalSupply += amount;

        emit IssuedByPartition(partitionId, to, amount);
    }

    /**
     * @notice Redeem (burn) tokens from a partition
     * @param partitionId Partition identifier
     * @param from Holder address
     * @param amount Amount to redeem
     */
    function redeemByPartition(
        bytes32 partitionId,
        address from,
        uint256 amount
    ) external onlyRole(CONTROLLER_ROLE) {
        require(from != address(0), "Invalid holder");
        require(partitionBalances[partitionId][from] >= amount, "Insufficient partition balance");

        // Burn tokens
        _burn(from, amount);
        
        // Update partition balance
        partitionBalances[partitionId][from] -= amount;
        partitions[partitionId].totalSupply -= amount;

        emit RedeemedByPartition(partitionId, from, amount);
    }

    // ============ Partition Transfers ============

    /**
     * @notice Transfer tokens within a partition
     * @param partitionId Partition identifier
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transferByPartition(
        bytes32 partitionId,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(partitionBalances[partitionId][msg.sender] >= amount, "Insufficient partition balance");
        
        Partition memory partition = partitions[partitionId];
        require(partition.partitionId != bytes32(0), "Partition not found");

        // Lock check
        if (partition.locked) {
            if (partition.lockExpiry == 0 || block.timestamp < partition.lockExpiry) {
                revert("Partition locked");
            }
        }

        // Compliance check
        (bool allowed, string memory reason) = complianceRegistry.preTransferCheck(
            partition.complianceClass,
            msg.sender,
            to,
            address(this),
            0 // tokenId (0 for fungible)
        );
        require(allowed, string(abi.encodePacked("Transfer blocked: ", reason)));

        // Transfer
        _transfer(msg.sender, to, amount);
        
        // Update partition balances
        partitionBalances[partitionId][msg.sender] -= amount;
        partitionBalances[partitionId][to] += amount;

        emit TransferByPartition(partitionId, msg.sender, to, amount);

        return true;
    }

    // ============ Controller Functions ============

    /**
     * @notice Force transfer (by controller)
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param reason Reason for controller transfer
     */
    function controllerTransfer(
        address from,
        address to,
        uint256 amount,
        string calldata reason
    ) external onlyRole(CONTROLLER_ROLE) {
        require(isControllable, "Token not controllable");
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(balanceOf(from) >= amount, "Insufficient balance");

        _transfer(from, to, amount);

        emit ControllerTransfer(msg.sender, from, to, amount, reason);
    }

    // ============ Document Management ============

    /**
     * @notice Publish a document
     * @param name Document name
     * @param uri Document URI (IPFS/HTTP)
     * @param documentHash Document hash
     */
    function publishDocument(
        string calldata name,
        string calldata uri,
        bytes32 documentHash
    ) external onlyRole(ADMIN_ROLE) {
        documents.push(Document({
            name: name,
            uri: uri,
            documentHash: documentHash,
            timestamp: block.timestamp
        }));

        emit DocumentPublished(documents.length - 1, name, uri);
    }

    /**
     * @notice Get document by index
     * @param index Document index
     * @return doc Document struct
     */
    function getDocument(uint256 index) external view returns (Document memory) {
        require(index < documents.length, "Document not found");
        return documents[index];
    }

    /**
     * @notice Get total document count
     * @return count Number of documents
     */
    function getDocumentCount() external view returns (uint256) {
        return documents.length;
    }

    // ============ View Functions ============

    /**
     * @notice Get partition balance for an address
     * @param partitionId Partition identifier
     * @param holder Holder address
     * @return balance Partition balance
     */
    function balanceOfByPartition(bytes32 partitionId, address holder) 
        external 
        view 
        returns (uint256) 
    {
        return partitionBalances[partitionId][holder];
    }

    /**
     * @notice Get partition info
     * @param partitionId Partition identifier
     * @return partition Partition struct
     */
    function getPartition(bytes32 partitionId) external view returns (Partition memory) {
        return partitions[partitionId];
    }

    // ============ Interface Support ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
