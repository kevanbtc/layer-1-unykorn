// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../tokens/ERC1155Carbon.sol";

/**
 * @title CarbonVault
 * @notice Locks ERC1155Carbon on Unykorn L1, enabling bridge to Polygon
 * @dev Source-side vault for LayerZero bridge
 * 
 * Flow:
 * 1. User locks carbon tokens here (ERC1155)
 * 2. Vault sends LayerZero message to Polygon
 * 3. UNYCarbonOFT mints wrapped tokens on Polygon (1:1)
 * 4. User burns wrapped tokens on Polygon → unlocks here
 */
contract CarbonVault is AccessControl, ReentrancyGuard {
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    ERC1155Carbon public carbonToken;
    address public lzEndpoint;
    
    // TokenId => locked amount
    mapping(uint256 => uint256) public locked;
    
    // User => TokenId => locked amount
    mapping(address => mapping(uint256 => uint256)) public userLocked;
    
    bool public paused;
    
    event Locked(address indexed user, uint256 tokenId, uint256 amount, uint16 dstChain);
    event Unlocked(address indexed user, uint256 tokenId, uint256 amount);
    event EmergencyWithdraw(address indexed admin, uint256 tokenId, uint256 amount);
    
    constructor(address _carbonToken, address _lzEndpoint) {
        carbonToken = ERC1155Carbon(_carbonToken);
        lzEndpoint = _lzEndpoint;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(BRIDGE_ROLE, msg.sender);
    }
    
    /**
     * @notice Lock carbon tokens to bridge to destination chain
     * @param tokenId Carbon token ID (e.g., Verra VCS project)
     * @param amount Amount to lock
     * @param dstChain LayerZero destination chain ID
     */
    function lockAndBridge(
        uint256 tokenId,
        uint256 amount,
        uint16 dstChain,
        address recipient
    ) external payable nonReentrant {
        require(!paused, "Vault paused");
        require(amount > 0, "Invalid amount");
        
        // Transfer tokens from user to vault
        carbonToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        
        locked[tokenId] += amount;
        userLocked[msg.sender][tokenId] += amount;
        
        emit Locked(msg.sender, tokenId, amount, dstChain);
        
        // TODO: Send LayerZero message to destination
        // Implementation requires LZ integration
    }
    
    /**
     * @notice Unlock tokens (called by bridge when user burns on destination)
     * @param user User to unlock for
     * @param tokenId Token ID
     * @param amount Amount to unlock
     */
    function unlock(
        address user,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(BRIDGE_ROLE) nonReentrant {
        require(locked[tokenId] >= amount, "Insufficient locked");
        require(userLocked[user][tokenId] >= amount, "User insufficient");
        
        locked[tokenId] -= amount;
        userLocked[user][tokenId] -= amount;
        
        carbonToken.safeTransferFrom(address(this), user, tokenId, amount, "");
        
        emit Unlocked(user, tokenId, amount);
    }
    
    /**
     * @notice Emergency withdraw (admin only, paused state)
     * @param tokenId Token ID
     * @param amount Amount
     * @param recipient Recipient
     */
    function emergencyWithdraw(
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) external onlyRole(ADMIN_ROLE) {
        require(paused, "Not paused");
        carbonToken.safeTransferFrom(address(this), recipient, tokenId, amount, "");
        emit EmergencyWithdraw(msg.sender, tokenId, amount);
    }
    
    /**
     * @notice Pause vault
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        paused = true;
    }
    
    /**
     * @notice Unpause vault
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        paused = false;
    }
    
    /**
     * @notice ERC1155 receiver
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
