// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LicenseNFT
 * @notice Self-executing IP license with on-chain royalty enforcement
 * @dev Soulbound by default, tracks license scope, royalties, and compliance
 */
contract LicenseNFT is ERC721Enumerable, Ownable {
    struct License {
        bytes32 scope;           // e.g., keccak256("ENERGY_GLOBAL_V1")
        uint16 royaltyBps;       // 0..10000 (basis points)
        uint64 paidThrough;      // Unix timestamp
        bool suspended;
        string termsCid;         // IPFS CID of license terms (includes TM/patent refs)
    }
    
    mapping(uint256 => License) public licenses;
    mapping(address => bool) public complianceOracle; // Can suspend/reinstate
    uint256 public nextId = 1;
    
    event AcceptedTerms(address indexed operator, string termsCid, bytes32 scope, uint256 tokenId);
    event RoyaltyPaid(address indexed operator, bytes32 eventType, uint256 amount);
    event Suspended(uint256 indexed tokenId, string reason);
    event Reinstated(uint256 indexed tokenId, string reason);
    event Extended(uint256 indexed tokenId, uint64 newPaidThrough);
    
    constructor() ERC721("UNY License", "UNYLIC") Ownable(msg.sender) {}
    
    /**
     * @notice Set compliance oracle (can suspend licenses)
     * @param oracle Oracle address
     * @param enabled True to enable, false to disable
     */
    function setComplianceOracle(address oracle, bool enabled) external onlyOwner {
        complianceOracle[oracle] = enabled;
    }
    
    /**
     * @notice Mint new license NFT
     * @param to License holder
     * @param scope License scope (e.g., "ENERGY_GLOBAL_V1")
     * @param royaltyBps Royalty in basis points (100 = 1%)
     * @param paidThrough Unix timestamp of license expiry
     * @param termsCid IPFS CID of license terms
     * @return tokenId Newly minted license ID
     */
    function mint(
        address to,
        bytes32 scope,
        uint16 royaltyBps,
        uint64 paidThrough,
        string calldata termsCid
    ) external onlyOwner returns (uint256) {
        require(royaltyBps <= 10_000, "Invalid royalty");
        require(paidThrough > block.timestamp, "Already expired");
        
        uint256 tokenId = nextId++;
        _safeMint(to, tokenId);
        
        licenses[tokenId] = License({
            scope: scope,
            royaltyBps: royaltyBps,
            paidThrough: paidThrough,
            suspended: false,
            termsCid: termsCid
        });
        
        emit AcceptedTerms(to, termsCid, scope, tokenId);
        return tokenId;
    }
    
    /**
     * @notice Check if operator has active license for scope
     * @param operator Address to check
     * @param scope License scope to verify
     * @return True if operator has valid, non-suspended license
     */
    function isActive(address operator, bytes32 scope) external view returns (bool) {
        uint256 balance = balanceOf(operator);
        if (balance == 0) return false;
        
        // Check all licenses held by operator
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(operator, i);
            License memory lic = licenses[tokenId];
            
            if (lic.scope == scope && 
                !lic.suspended && 
                block.timestamp <= lic.paidThrough) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * @notice Pay royalty (funds held in contract)
     * @param eventType Event type (e.g., "ISSUANCE", "TRANSFER")
     */
    function payRoyalty(bytes32 eventType) external payable {
        require(msg.value > 0, "No payment");
        emit RoyaltyPaid(msg.sender, eventType, msg.value);
    }
    
    /**
     * @notice Extend license expiry
     * @param tokenId License ID
     * @param newPaidThrough New expiry timestamp
     */
    function extend(uint256 tokenId, uint64 newPaidThrough) external onlyOwner {
        require(ownerOf(tokenId) != address(0), "Invalid token");
        require(newPaidThrough > licenses[tokenId].paidThrough, "Must extend forward");
        
        licenses[tokenId].paidThrough = newPaidThrough;
        emit Extended(tokenId, newPaidThrough);
    }
    
    /**
     * @notice Suspend license (compliance breach)
     * @param tokenId License ID
     * @param reason Suspension reason
     */
    function suspend(uint256 tokenId, string calldata reason) external {
        require(complianceOracle[msg.sender] || msg.sender == owner(), "Unauthorized");
        require(ownerOf(tokenId) != address(0), "Invalid token");
        
        licenses[tokenId].suspended = true;
        emit Suspended(tokenId, reason);
    }
    
    /**
     * @notice Reinstate suspended license
     * @param tokenId License ID
     * @param reason Reinstatement reason
     */
    function reinstate(uint256 tokenId, string calldata reason) external onlyOwner {
        require(ownerOf(tokenId) != address(0), "Invalid token");
        
        licenses[tokenId].suspended = false;
        emit Reinstated(tokenId, reason);
    }
    
    /**
     * @notice Withdraw collected royalties
     * @param to Recipient address
     */
    function withdrawRoyalties(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");
        
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev Soulbound: Prevent transfers except minting/burning
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        
        // Allow minting
        if (from == address(0)) {
            return super._update(to, tokenId, auth);
        }
        
        // Allow owner to force transfer (recovery/emergency)
        if (msg.sender == owner()) {
            return super._update(to, tokenId, auth);
        }
        
        // Block all other transfers
        revert("LicenseNFT: Soulbound");
    }
}
