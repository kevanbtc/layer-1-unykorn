// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/OFTV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title UNYCarbonOFT
 * @notice LayerZero Omnichain Fungible Token for Carbon Credits
 * @dev Bridges ERC1155Carbon from Unykorn L1 to Polygon/Ethereum
 * 
 * Architecture:
 * - L1 (7777): Lock ERC1155Carbon in vault → send LZ message
 * - Polygon (137): Receive LZ message → mint wUNY-Carbon (this contract)
 * - Burn on Polygon → unlock on L1
 */
contract UNYCarbonOFT is OFTV2, AccessControl {
    bytes32 public constant BRIDGE_ADMIN_ROLE = keccak256("BRIDGE_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    address public sourceVault;  // L1 vault holding real carbon tokens
    uint16 public sourceChainId; // LayerZero chainId for Unykorn L1
    
    bool public paused;
    
    event VaultUpdated(address indexed oldVault, address indexed newVault);
    event SourceChainUpdated(uint16 oldChain, uint16 newChain);
    event EmergencyPaused(address indexed admin);
    event EmergencyUnpaused(address indexed admin);
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _sourceVault,
        uint16 _sourceChainId
    ) OFTV2(_name, _symbol, 6, _lzEndpoint) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BRIDGE_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        
        sourceVault = _sourceVault;
        sourceChainId = _sourceChainId;
    }
    
    /**
     * @notice Update source vault address (L1)
     * @param newVault New vault address on source chain
     */
    function setSourceVault(address newVault) external onlyRole(BRIDGE_ADMIN_ROLE) {
        require(newVault != address(0), "Invalid vault");
        emit VaultUpdated(sourceVault, newVault);
        sourceVault = newVault;
    }
    
    /**
     * @notice Update source chain ID
     * @param newChainId New LayerZero chain ID
     */
    function setSourceChain(uint16 newChainId) external onlyRole(BRIDGE_ADMIN_ROLE) {
        emit SourceChainUpdated(sourceChainId, newChainId);
        sourceChainId = newChainId;
    }
    
    /**
     * @notice Emergency pause (stops all bridging)
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }
    
    /**
     * @notice Unpause
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }
    
    /**
     * @notice Override to add pause check
     */
    function _debitFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint _amount
    ) internal override returns (uint) {
        require(!paused, "Bridge paused");
        return super._debitFrom(_from, _dstChainId, _toAddress, _amount);
    }
    
    /**
     * @notice Override to add pause check
     */
    function _creditTo(
        uint16 _srcChainId,
        address _toAddress,
        uint _amount
    ) internal override returns (uint) {
        require(!paused, "Bridge paused");
        return super._creditTo(_srcChainId, _toAddress, _amount);
    }
}
