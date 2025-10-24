// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ERC1400TaxEquity
 * @notice Tax equity partnership interests (ITC/PTC structures)
 * @dev Security token with partitions for flip structures
 * @dev Uses ERC20 base with partition accounting (simplified ERC1400 pattern)
 */
contract ERC1400TaxEquity is ERC20, AccessControl, ReentrancyGuard {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    // Partition names
    bytes32 public constant SPONSOR_PARTITION = keccak256("SPONSOR");
    bytes32 public constant INVESTOR_PARTITION = keccak256("INVESTOR");
    
    // Partition balances (address => partition => balance)
    mapping(address => mapping(bytes32 => uint256)) public balanceOfByPartition;
    mapping(bytes32 => uint256) public totalSupplyByPartition;
    
    struct Partnership {
        bytes32 projectId;
        uint8 creditType;        // 0=ITC, 1=PTC
        uint256 projectCost;     // USD (scaled by 10^18)
        uint16 itcPercent;       // ITC percentage (3000 = 30%)
        uint256 ptcRate;         // PTC rate per MWh (scaled by 10^18)
        uint64 flipDate;         // Unix timestamp of flip
        bool flipped;
        uint16 preFlipInvestor;  // Investor % pre-flip (e.g., 9900 = 99%)
        uint16 postFlipInvestor; // Investor % post-flip (e.g., 500 = 5%)
    }
    
    Partnership public partnership;
    
    event PartnershipCreated(
        bytes32 projectId,
        uint8 creditType,
        uint256 projectCost,
        uint64 flipDate
    );
    event Flipped(uint64 timestamp, uint16 newInvestorPercent);
    event DistributionMade(bytes32 indexed partition, uint256 amount);
    
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }
    
    /**
     * @notice Issue tokens to partition
     * @param partition Partition name (SPONSOR_PARTITION or INVESTOR_PARTITION)
     * @param to Recipient address
     * @param amount Amount to issue
     */
    function issueByPartition(bytes32 partition, address to, uint256 amount)
        external
        onlyRole(ISSUER_ROLE)
        nonReentrant
    {
        require(partition == SPONSOR_PARTITION || partition == INVESTOR_PARTITION, "Invalid partition");
        
        _mint(to, amount);
        balanceOfByPartition[to][partition] += amount;
        totalSupplyByPartition[partition] += amount;
    }
    
    /**
     * @notice Initialize partnership structure
     * @param projectId Unique project identifier
     * @param creditType 0=ITC, 1=PTC
     * @param projectCost Total project cost (USD, scaled by 10^18)
     * @param itcPercent ITC percentage (3000 = 30%)
     * @param ptcRate PTC rate per MWh (scaled by 10^18)
     * @param flipDate Unix timestamp when flip occurs
     * @param preFlipInvestor Investor % pre-flip (e.g., 9900 = 99%)
     * @param postFlipInvestor Investor % post-flip (e.g., 500 = 5%)
     */
    function initializePartnership(
        bytes32 projectId,
        uint8 creditType,
        uint256 projectCost,
        uint16 itcPercent,
        uint256 ptcRate,
        uint64 flipDate,
        uint16 preFlipInvestor,
        uint16 postFlipInvestor
    ) external onlyRole(ADMIN_ROLE) {
        require(partnership.projectId == bytes32(0), "Already initialized");
        require(creditType <= 1, "Invalid credit type");
        require(flipDate > block.timestamp, "Flip date in past");
        require(preFlipInvestor + (10000 - preFlipInvestor) == 10000, "Invalid pre-flip %");
        require(postFlipInvestor + (10000 - postFlipInvestor) == 10000, "Invalid post-flip %");
        
        partnership = Partnership({
            projectId: projectId,
            creditType: creditType,
            projectCost: projectCost,
            itcPercent: itcPercent,
            ptcRate: ptcRate,
            flipDate: flipDate,
            flipped: false,
            preFlipInvestor: preFlipInvestor,
            postFlipInvestor: postFlipInvestor
        });
        
        emit PartnershipCreated(projectId, creditType, projectCost, flipDate);
    }
    
    /**
     * @notice Execute flip (changes distribution percentages)
     */
    function executeFlip() external onlyRole(ADMIN_ROLE) {
        require(block.timestamp >= partnership.flipDate, "Too early");
        require(!partnership.flipped, "Already flipped");
        
        partnership.flipped = true;
        
        emit Flipped(uint64(block.timestamp), partnership.postFlipInvestor);
    }
    
    /**
     * @notice Distribute cash flows to partitions
     * @param sponsorAmount Amount to sponsor partition
     * @param investorAmount Amount to investor partition
     */
    function distribute(uint256 sponsorAmount, uint256 investorAmount)
        external
        onlyRole(ADMIN_ROLE)
    {
        // In real implementation, would transfer actual funds
        // For now, just emit events
        
        if (sponsorAmount > 0) {
            emit DistributionMade(SPONSOR_PARTITION, sponsorAmount);
        }
        
        if (investorAmount > 0) {
            emit DistributionMade(INVESTOR_PARTITION, investorAmount);
        }
    }
    
    /**
     * @notice Calculate current distribution percentages
     * @return sponsorPercent Sponsor percentage (basis points)
     * @return investorPercent Investor percentage (basis points)
     */
    function getCurrentDistribution() external view returns (uint16 sponsorPercent, uint16 investorPercent) {
        if (partnership.flipped) {
            investorPercent = partnership.postFlipInvestor;
            sponsorPercent = 10000 - investorPercent;
        } else {
            investorPercent = partnership.preFlipInvestor;
            sponsorPercent = 10000 - investorPercent;
        }
        
        return (sponsorPercent, investorPercent);
    }
    
    /**
     * @notice Calculate ITC credit value
     * @return ITC amount (USD, scaled by 10^18)
     */
    function calculateITC() external view returns (uint256) {
        require(partnership.creditType == 0, "Not ITC partnership");
        return (partnership.projectCost * partnership.itcPercent) / 10000;
    }
    
    /**
     * @notice Calculate PTC credit value for generation
     * @param generationMWh Generation in MWh
     * @return PTC amount (USD, scaled by 10^18)
     */
    function calculatePTC(uint256 generationMWh) external view returns (uint256) {
        require(partnership.creditType == 1, "Not PTC partnership");
        return generationMWh * partnership.ptcRate;
    }
    
    /**
     * @notice Get partitions for account
     * @param account Address to query
     * @return Array of partition names
     */
    function partitionsOf(address account) external view returns (bytes32[] memory) {
        bytes32[] memory partitions = new bytes32[](2);
        uint256 count = 0;
        
        if (balanceOfByPartition[account][SPONSOR_PARTITION] > 0) {
            partitions[count++] = SPONSOR_PARTITION;
        }
        if (balanceOfByPartition[account][INVESTOR_PARTITION] > 0) {
            partitions[count++] = INVESTOR_PARTITION;
        }
        
        // Resize array
        bytes32[] memory result = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = partitions[i];
        }
        
        return result;
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
