// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IIdentityRegistry {
    function isVerified(address account) external view returns (bool);
}

interface IComplianceModule {
    function canTransfer(address from, address to, uint256 amount) external view returns (bool);
}

/**
 * @title ERC3643Adapter
 * @notice T-REX (ERC-3643) compliant security token adapter
 * @dev Bridges UNY-ID identity system with T-REX standard
 */
contract ERC3643Adapter is ERC20, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    
    IIdentityRegistry public identityRegistry;
    IComplianceModule public complianceModule;
    
    bool public transfersEnabled = true;
    mapping(address => bool) public frozen;
    
    event IdentityRegistrySet(address indexed registry);
    event ComplianceModuleSet(address indexed module);
    event TransfersToggled(bool enabled);
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event ForcedTransfer(address indexed from, address indexed to, uint256 amount, string reason);
    
    constructor(
        string memory name,
        string memory symbol,
        address _identityRegistry,
        address _complianceModule
    ) ERC20(name, symbol) {
        require(_identityRegistry != address(0), "Invalid identity registry");
        require(_complianceModule != address(0), "Invalid compliance module");
        
        identityRegistry = IIdentityRegistry(_identityRegistry);
        complianceModule = IComplianceModule(_complianceModule);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
        _grantRole(AGENT_ROLE, msg.sender);
    }
    
    /**
     * @notice Set identity registry
     * @param registry New registry address
     */
    function setIdentityRegistry(address registry) external onlyRole(ADMIN_ROLE) {
        require(registry != address(0), "Invalid address");
        identityRegistry = IIdentityRegistry(registry);
        emit IdentityRegistrySet(registry);
    }
    
    /**
     * @notice Set compliance module
     * @param module New compliance module address
     */
    function setComplianceModule(address module) external onlyRole(ADMIN_ROLE) {
        require(module != address(0), "Invalid address");
        complianceModule = IComplianceModule(module);
        emit ComplianceModuleSet(module);
    }
    
    /**
     * @notice Toggle global transfers
     * @param enabled True to enable, false to disable
     */
    function setTransfersEnabled(bool enabled) external onlyRole(ADMIN_ROLE) {
        transfersEnabled = enabled;
        emit TransfersToggled(enabled);
    }
    
    /**
     * @notice Freeze account (compliance/court order)
     * @param account Address to freeze
     */
    function freeze(address account) external onlyRole(AGENT_ROLE) {
        frozen[account] = true;
        emit AccountFrozen(account);
    }
    
    /**
     * @notice Unfreeze account
     * @param account Address to unfreeze
     */
    function unfreeze(address account) external onlyRole(AGENT_ROLE) {
        frozen[account] = false;
        emit AccountUnfrozen(account);
    }
    
    /**
     * @notice Issue tokens
     * @param to Recipient address
     * @param amount Amount to issue
     */
    function issue(address to, uint256 amount) external onlyRole(ISSUER_ROLE) {
        require(identityRegistry.isVerified(to), "Recipient not verified");
        _mint(to, amount);
    }
    
    /**
     * @notice Forced transfer (court order/recovery)
     * @param from Source address
     * @param to Destination address
     * @param amount Amount to transfer
     * @param reason Reason for forced transfer
     */
    function forcedTransfer(address from, address to, uint256 amount, string calldata reason)
        external
        onlyRole(AGENT_ROLE)
    {
        require(identityRegistry.isVerified(to), "Recipient not verified");
        _transfer(from, to, amount);
        emit ForcedTransfer(from, to, amount, reason);
    }
    
    /**
     * @notice Burn tokens
     * @param account Address to burn from
     * @param amount Amount to burn
     */
    function burn(address account, uint256 amount) external onlyRole(ISSUER_ROLE) {
        _burn(account, amount);
    }
    
    /**
     * @dev Override transfer with compliance checks
     */
    function _update(address from, address to, uint256 amount) internal override {
        // Allow minting/burning
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }
        
        // Allow forced transfers from agents
        if (hasRole(AGENT_ROLE, msg.sender)) {
            super._update(from, to, amount);
            return;
        }
        
        // Check global transfers enabled
        require(transfersEnabled, "Transfers disabled");
        
        // Check frozen accounts
        require(!frozen[from], "Sender frozen");
        require(!frozen[to], "Recipient frozen");
        
        // Check identity verification
        require(identityRegistry.isVerified(from), "Sender not verified");
        require(identityRegistry.isVerified(to), "Recipient not verified");
        
        // Check compliance rules
        require(complianceModule.canTransfer(from, to, amount), "Transfer not compliant");
        
        super._update(from, to, amount);
    }
    
    /**
     * @notice Check if transfer is allowed
     * @param from Source address
     * @param to Destination address
     * @param amount Amount to transfer
     * @return True if transfer allowed
     */
    function canTransfer(address from, address to, uint256 amount) external view returns (bool) {
        if (!transfersEnabled) return false;
        if (frozen[from] || frozen[to]) return false;
        if (!identityRegistry.isVerified(from) || !identityRegistry.isVerified(to)) return false;
        return complianceModule.canTransfer(from, to, amount);
    }
    
    /**
     * @notice Check interface support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
