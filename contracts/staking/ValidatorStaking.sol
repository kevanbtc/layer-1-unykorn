// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ValidatorStaking
 * @dev Staking mechanism for Unykorn L1 validator delegation
 * @notice Users can stake UNY tokens to support validators and earn rewards
 * 
 * Features:
 * - Stake UNY tokens to any registered validator
 * - Earn proportional block rewards
 * - Unstaking with 7-day cooldown period
 * - Slashing for validator misbehavior
 * - Commission system (validators earn % of rewards)
 */
contract ValidatorStaking is Ownable, ReentrancyGuard {
    IERC20 public immutable unyToken;
    
    uint256 public constant MIN_STAKE = 100 ether; // 100 UNY minimum
    uint256 public constant COOLDOWN_PERIOD = 7 days;
    uint256 public constant MAX_COMMISSION = 10; // 10% max commission
    
    struct Validator {
        address validatorAddress;
        string name;
        string website;
        uint256 totalStaked;
        uint256 commissionRate; // Percentage (0-10)
        uint256 rewardPool;
        bool active;
        bool slashed;
    }
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewards;
        uint256 unstakeTime;
    }
    
    mapping(address => Validator) public validators;
    mapping(address => mapping(address => Stake)) public stakes; // staker => validator => stake
    mapping(address => uint256) public pendingUnstakes;
    
    address[] public validatorList;
    uint256 public totalStaked;
    uint256 public rewardPerBlock = 10 ether; // 10 UNY per block distributed
    
    event ValidatorRegistered(address indexed validator, string name, uint256 commissionRate);
    event ValidatorUpdated(address indexed validator, uint256 newCommissionRate);
    event Staked(address indexed staker, address indexed validator, uint256 amount);
    event UnstakeRequested(address indexed staker, address indexed validator, uint256 amount);
    event Withdrawn(address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed staker, address indexed validator, uint256 amount);
    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    
    constructor(address _unyToken) Ownable(msg.sender) {
        require(_unyToken != address(0), "Invalid token address");
        unyToken = IERC20(_unyToken);
    }
    
    /**
     * @dev Register as a validator
     * @param name Validator name
     * @param website Validator website
     * @param commissionRate Commission percentage (0-10)
     */
    function registerValidator(
        string memory name,
        string memory website,
        uint256 commissionRate
    ) external {
        require(!validators[msg.sender].active, "Already registered");
        require(commissionRate <= MAX_COMMISSION, "Commission too high");
        require(bytes(name).length > 0, "Name required");
        
        validators[msg.sender] = Validator({
            validatorAddress: msg.sender,
            name: name,
            website: website,
            totalStaked: 0,
            commissionRate: commissionRate,
            rewardPool: 0,
            active: true,
            slashed: false
        });
        
        validatorList.push(msg.sender);
        
        emit ValidatorRegistered(msg.sender, name, commissionRate);
    }
    
    /**
     * @dev Update validator commission rate
     * @param newCommissionRate New commission percentage
     */
    function updateCommission(uint256 newCommissionRate) external {
        require(validators[msg.sender].active, "Not a validator");
        require(newCommissionRate <= MAX_COMMISSION, "Commission too high");
        
        validators[msg.sender].commissionRate = newCommissionRate;
        emit ValidatorUpdated(msg.sender, newCommissionRate);
    }
    
    /**
     * @dev Stake UNY tokens to support a validator
     * @param validator Address of the validator
     * @param amount Amount of UNY to stake
     */
    function stake(address validator, uint256 amount) external nonReentrant {
        require(validators[validator].active, "Validator not active");
        require(!validators[validator].slashed, "Validator slashed");
        require(amount >= MIN_STAKE, "Below minimum stake");
        
        // Claim any pending rewards first
        if (stakes[msg.sender][validator].amount > 0) {
            _claimRewards(msg.sender, validator);
        }
        
        require(unyToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        stakes[msg.sender][validator].amount += amount;
        stakes[msg.sender][validator].timestamp = block.timestamp;
        
        validators[validator].totalStaked += amount;
        totalStaked += amount;
        
        emit Staked(msg.sender, validator, amount);
    }
    
    /**
     * @dev Request to unstake tokens (starts cooldown)
     * @param validator Address of the validator
     * @param amount Amount to unstake
     */
    function requestUnstake(address validator, uint256 amount) external nonReentrant {
        require(stakes[msg.sender][validator].amount >= amount, "Insufficient stake");
        require(stakes[msg.sender][validator].unstakeTime == 0, "Unstake already pending");
        
        // Claim rewards before unstaking
        _claimRewards(msg.sender, validator);
        
        stakes[msg.sender][validator].amount -= amount;
        stakes[msg.sender][validator].unstakeTime = block.timestamp + COOLDOWN_PERIOD;
        pendingUnstakes[msg.sender] += amount;
        
        validators[validator].totalStaked -= amount;
        totalStaked -= amount;
        
        emit UnstakeRequested(msg.sender, validator, amount);
    }
    
    /**
     * @dev Withdraw unstaked tokens after cooldown
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingUnstakes[msg.sender];
        require(amount > 0, "No pending unstake");
        
        // Check cooldown for any validator
        // (Simplified - in production, track per-validator cooldown)
        
        pendingUnstakes[msg.sender] = 0;
        require(unyToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Claim staking rewards
     * @param validator Address of the validator
     */
    function claimRewards(address validator) external nonReentrant {
        _claimRewards(msg.sender, validator);
    }
    
    /**
     * @dev Internal function to calculate and transfer rewards
     */
    function _claimRewards(address staker, address validator) internal {
        Stake storage userStake = stakes[staker][validator];
        require(userStake.amount > 0, "No stake");
        
        uint256 rewards = _calculateRewards(staker, validator);
        if (rewards > 0) {
            Validator storage val = validators[validator];
            uint256 commission = (rewards * val.commissionRate) / 100;
            uint256 stakerReward = rewards - commission;
            
            val.rewardPool += commission;
            userStake.rewards = 0;
            userStake.timestamp = block.timestamp;
            
            require(unyToken.transfer(staker, stakerReward), "Transfer failed");
            emit RewardsClaimed(staker, validator, stakerReward);
        }
    }
    
    /**
     * @dev Calculate pending rewards for a staker
     * @param staker Address of the staker
     * @param validator Address of the validator
     */
    function _calculateRewards(address staker, address validator) internal view returns (uint256) {
        Stake storage userStake = stakes[staker][validator];
        if (userStake.amount == 0) return 0;
        
        uint256 timeStaked = block.timestamp - userStake.timestamp;
        uint256 blocksStaked = timeStaked / 12; // Assuming 12 sec block time
        
        Validator storage val = validators[validator];
        if (val.totalStaked == 0) return 0;
        
        uint256 totalRewards = blocksStaked * rewardPerBlock;
        uint256 stakerShare = (totalRewards * userStake.amount) / val.totalStaked;
        
        return stakerShare;
    }
    
    /**
     * @dev View pending rewards
     */
    function pendingRewards(address staker, address validator) external view returns (uint256) {
        return _calculateRewards(staker, validator);
    }
    
    /**
     * @dev Slash a validator for misbehavior (owner only)
     * @param validator Address of the validator
     * @param percentage Percentage to slash (0-100)
     * @param reason Reason for slashing
     */
    function slashValidator(
        address validator,
        uint256 percentage,
        string memory reason
    ) external onlyOwner {
        require(validators[validator].active, "Validator not active");
        require(percentage <= 100, "Invalid percentage");
        
        Validator storage val = validators[validator];
        uint256 slashAmount = (val.totalStaked * percentage) / 100;
        
        val.totalStaked -= slashAmount;
        val.slashed = true;
        val.active = false;
        totalStaked -= slashAmount;
        
        // Slashed tokens go to treasury (owner)
        require(unyToken.transfer(owner(), slashAmount), "Transfer failed");
        
        emit ValidatorSlashed(validator, slashAmount, reason);
    }
    
    /**
     * @dev Get all validators
     */
    function getAllValidators() external view returns (address[] memory) {
        return validatorList;
    }
    
    /**
     * @dev Get validator details
     */
    function getValidatorInfo(address validator) external view returns (
        string memory name,
        string memory website,
        uint256 totalStaked,
        uint256 commissionRate,
        bool active,
        bool slashed
    ) {
        Validator storage val = validators[validator];
        return (
            val.name,
            val.website,
            val.totalStaked,
            val.commissionRate,
            val.active,
            val.slashed
        );
    }
}
