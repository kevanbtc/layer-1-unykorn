// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RetirementAttestation
 * @notice Public retirement registry with attestations
 * @dev Immutable retirement records with third-party verification
 */
contract RetirementAttestation is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    
    struct Retirement {
        address account;
        bytes32 assetType;     // "REC", "CARBON", etc.
        uint256 tokenId;       // Token ID (for ERC1155)
        uint256 amount;
        string beneficiary;    // Beneficiary name/description
        uint64 timestamp;
        bytes32 certCid;       // IPFS CID of certificate
        bool verified;         // Third-party verified
    }
    
    Retirement[] public retirements;
    
    // Account => retirement indices
    mapping(address => uint256[]) public retirementsByAccount;
    
    // Beneficiary hash => retirement indices
    mapping(bytes32 => uint256[]) public retirementsByBeneficiary;
    
    uint256 public totalRetired;
    
    event Retired(
        uint256 indexed retirementId,
        address indexed account,
        bytes32 assetType,
        uint256 amount,
        string beneficiary,
        bytes32 certCid
    );
    event Verified(uint256 indexed retirementId, address indexed verifier);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
    }
    
    /**
     * @notice Record retirement
     * @param account Retiring account
     * @param assetType Asset type identifier
     * @param tokenId Token ID (for ERC1155, 0 for ERC20)
     * @param amount Amount retired
     * @param beneficiary Beneficiary name/description
     * @param certCid IPFS CID of retirement certificate
     * @return retirementId New retirement ID
     */
    function recordRetirement(
        address account,
        bytes32 assetType,
        uint256 tokenId,
        uint256 amount,
        string calldata beneficiary,
        bytes32 certCid
    ) external onlyRole(ADMIN_ROLE) returns (uint256) {
        require(amount > 0, "Invalid amount");
        
        uint256 retirementId = retirements.length;
        
        retirements.push(Retirement({
            account: account,
            assetType: assetType,
            tokenId: tokenId,
            amount: amount,
            beneficiary: beneficiary,
            timestamp: uint64(block.timestamp),
            certCid: certCid,
            verified: false
        }));
        
        retirementsByAccount[account].push(retirementId);
        retirementsByBeneficiary[keccak256(bytes(beneficiary))].push(retirementId);
        
        totalRetired += amount;
        
        emit Retired(retirementId, account, assetType, amount, beneficiary, certCid);
        
        return retirementId;
    }
    
    /**
     * @notice Verify retirement (third-party attestation)
     * @param retirementId Retirement ID to verify
     */
    function verify(uint256 retirementId) external onlyRole(VERIFIER_ROLE) {
        require(retirementId < retirements.length, "Invalid ID");
        require(!retirements[retirementId].verified, "Already verified");
        
        retirements[retirementId].verified = true;
        
        emit Verified(retirementId, msg.sender);
    }
    
    /**
     * @notice Get retirement by ID
     * @param retirementId Retirement ID
     * @return Retirement struct
     */
    function getRetirement(uint256 retirementId) external view returns (Retirement memory) {
        require(retirementId < retirements.length, "Invalid ID");
        return retirements[retirementId];
    }
    
    /**
     * @notice Get retirements for account
     * @param account Account address
     * @return Array of retirement IDs
     */
    function getRetirementsByAccount(address account) external view returns (uint256[] memory) {
        return retirementsByAccount[account];
    }
    
    /**
     * @notice Get retirements for beneficiary
     * @param beneficiary Beneficiary name
     * @return Array of retirement IDs
     */
    function getRetirementsByBeneficiary(string calldata beneficiary)
        external
        view
        returns (uint256[] memory)
    {
        return retirementsByBeneficiary[keccak256(bytes(beneficiary))];
    }
    
    /**
     * @notice Get total retirements count
     * @return Count
     */
    function getRetirementCount() external view returns (uint256) {
        return retirements.length;
    }
    
    /**
     * @notice Get account retirement totals
     * @param account Account address
     * @return totalAmount Total amount retired
     * @return retirementCount Number of retirements
     */
    function getAccountStats(address account)
        external
        view
        returns (uint256 totalAmount, uint256 retirementCount)
    {
        uint256[] memory ids = retirementsByAccount[account];
        retirementCount = ids.length;
        
        for (uint256 i = 0; i < ids.length; i++) {
            totalAmount += retirements[ids[i]].amount;
        }
        
        return (totalAmount, retirementCount);
    }
}
