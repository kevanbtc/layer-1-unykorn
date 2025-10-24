// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ERC1155Carbon
 * @notice Carbon credits with standard/vintage/project tracking
 * @dev Supports Verra VCS, Gold Standard, ACR, Puro.earth, CAR
 */
contract ERC1155Carbon is ERC1155, AccessControl, ReentrancyGuard {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    struct CreditType {
        bytes32 standard;      // "VERRA_VCS", "GOLD_STANDARD", "ACR", "PURO", "CAR"
        bytes32 methodology;   // Methodology ID
        bytes32 projectId;     // Unique project identifier
        uint16 vintage;        // Year (e.g., 2024)
        bytes32 geography;     // ISO country code
        bytes32 cobenefits;    // SDG tags
        string metadataUri;    // IPFS CID with full project data
        bool active;
    }
    
    // Token ID => Credit type
    mapping(uint256 => CreditType) public credits;
    
    // Retirement tracking
    mapping(address => mapping(uint256 => uint256)) public retired;
    uint256 public totalRetired;
    
    uint256 public nextId = 1;
    
    event CreditTypeCreated(
        uint256 indexed tokenId,
        bytes32 standard,
        bytes32 methodology,
        bytes32 projectId,
        uint16 vintage
    );
    event Retired(address indexed account, uint256 indexed tokenId, uint256 amount, string beneficiary);
    event CreditTypeDeactivated(uint256 indexed tokenId, string reason);
    
    constructor() ERC1155("https://metadata.unykorn.io/carbon/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }
    
    /**
     * @notice Create new credit type
     * @param standard Credit standard (e.g., "VERRA_VCS")
     * @param methodology Methodology ID
     * @param projectId Project identifier
     * @param vintage Vintage year
     * @param geography ISO country code
     * @param cobenefits SDG tags
     * @param metadataUri IPFS CID
     * @return tokenId New token ID
     */
    function createCreditType(
        bytes32 standard,
        bytes32 methodology,
        bytes32 projectId,
        uint16 vintage,
        bytes32 geography,
        bytes32 cobenefits,
        string calldata metadataUri
    ) external onlyRole(ADMIN_ROLE) returns (uint256) {
        require(vintage >= 2000 && vintage <= 2100, "Invalid vintage");
        
        uint256 tokenId = nextId++;
        
        credits[tokenId] = CreditType({
            standard: standard,
            methodology: methodology,
            projectId: projectId,
            vintage: vintage,
            geography: geography,
            cobenefits: cobenefits,
            metadataUri: metadataUri,
            active: true
        });
        
        emit CreditTypeCreated(tokenId, standard, methodology, projectId, vintage);
        return tokenId;
    }
    
    /**
     * @notice Issue carbon credits
     * @param to Recipient address
     * @param tokenId Credit type ID
     * @param amount Amount to issue (in tCO2e, scaled by 10^18)
     * @param data Optional data
     */
    function issue(address to, uint256 tokenId, uint256 amount, bytes calldata data)
        external
        onlyRole(ISSUER_ROLE)
        nonReentrant
    {
        require(credits[tokenId].active, "Credit type not active");
        _mint(to, tokenId, amount, data);
    }
    
    /**
     * @notice Batch issue carbon credits
     * @param to Recipient address
     * @param tokenIds Array of credit type IDs
     * @param amounts Array of amounts
     * @param data Optional data
     */
    function batchIssue(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyRole(ISSUER_ROLE) nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(credits[tokenIds[i]].active, "Credit type not active");
        }
        _mintBatch(to, tokenIds, amounts, data);
    }
    
    /**
     * @notice Retire carbon credits (permanent removal)
     * @param tokenId Credit type ID
     * @param amount Amount to retire
     * @param beneficiary Beneficiary name/description
     */
    function retire(uint256 tokenId, uint256 amount, string calldata beneficiary)
        external
        nonReentrant
    {
        require(balanceOf(msg.sender, tokenId) >= amount, "Insufficient balance");
        
        _burn(msg.sender, tokenId, amount);
        
        retired[msg.sender][tokenId] += amount;
        totalRetired += amount;
        
        emit Retired(msg.sender, tokenId, amount, beneficiary);
    }
    
    /**
     * @notice Deactivate credit type (fraud/scandal)
     * @param tokenId Credit type ID
     * @param reason Deactivation reason
     */
    function deactivateCreditType(uint256 tokenId, string calldata reason)
        external
        onlyRole(ADMIN_ROLE)
    {
        credits[tokenId].active = false;
        emit CreditTypeDeactivated(tokenId, reason);
    }
    
    /**
     * @notice Get credit type metadata URI
     * @param tokenId Token ID
     * @return Metadata URI
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(credits[tokenId].vintage > 0, "Token does not exist");
        return credits[tokenId].metadataUri;
    }
    
    /**
     * @notice Check interface support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
