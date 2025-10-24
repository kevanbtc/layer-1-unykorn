// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LaunchVault
 * @notice Early supporter contribution vault with NFT minting
 * @dev Collects MATIC, mints VaultProof NFTs, distributes to treasury
 */
contract LaunchVault is Ownable, ReentrancyGuard {
    address public immutable complianceRegistry;
    address public immutable vaultProofNFT;
    
    uint256 public mintPrice;
    address public treasury;
    uint256 public totalContributions;
    uint256 public totalParticipants;
    
    bool public mintingActive = true;
    
    mapping(address => uint256) public contributions;
    mapping(address => bool) public hasMinted;
    
    event Contributed(address indexed participant, uint256 amount, uint256 tokenId);
    event MintPriceUpdated(uint256 newPrice);
    event TreasuryUpdated(address newTreasury);
    event MintingStatusChanged(bool active);
    event Withdrawn(address indexed to, uint256 amount);
    
    constructor(
        address _complianceRegistry,
        address _vaultProofNFT,
        uint256 _mintPrice
    ) Ownable(msg.sender) {
        require(_complianceRegistry != address(0), "Invalid compliance registry");
        require(_vaultProofNFT != address(0), "Invalid NFT contract");
        require(_mintPrice > 0, "Invalid mint price");
        
        complianceRegistry = _complianceRegistry;
        vaultProofNFT = _vaultProofNFT;
        mintPrice = _mintPrice;
        treasury = msg.sender;
    }
    
    /**
     * @notice Participate in vault and mint VaultProof NFT
     */
    function mint() external payable nonReentrant {
        require(mintingActive, "Minting paused");
        require(msg.value >= mintPrice, "Insufficient payment");
        require(!hasMinted[msg.sender], "Already minted");
        
        // Record contribution
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        
        if (!hasMinted[msg.sender]) {
            totalParticipants++;
            hasMinted[msg.sender] = true;
        }
        
        // Mint NFT to participant
        (bool success, bytes memory data) = vaultProofNFT.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, msg.value)
        );
        require(success, "NFT mint failed");
        uint256 tokenId = abi.decode(data, (uint256));
        
        emit Contributed(msg.sender, msg.value, tokenId);
        
        // Refund excess
        if (msg.value > mintPrice) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - mintPrice}("");
            require(refundSuccess, "Refund failed");
        }
    }
    
    /**
     * @notice Update mint price
     * @param newPrice New price in wei
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid price");
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }
    
    /**
     * @notice Update treasury address
     * @param newTreasury New treasury address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid address");
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }
    
    /**
     * @notice Toggle minting status
     * @param active True to enable, false to disable
     */
    function setMintingActive(bool active) external onlyOwner {
        mintingActive = active;
        emit MintingStatusChanged(active);
    }
    
    /**
     * @notice Withdraw collected funds to treasury
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(treasury, balance);
    }
    
    /**
     * @notice Emergency withdraw to specific address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient balance");
        
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(to, amount);
    }
    
    /**
     * @notice Get contract balance
     * @return Balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        // Accept MATIC but don't auto-mint (require explicit mint() call)
    }
}
