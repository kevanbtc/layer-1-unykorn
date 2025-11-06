// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Governance
 * @dev On-chain governance for Unykorn L1 protocol upgrades and parameter changes
 * @notice This contract enables decentralized decision-making through proposals and voting
 * 
 * Features:
 * - Proposal creation with minimum stake requirement
 * - Token-weighted voting (1 UNY = 1 vote)
 * - Timelock for execution (48 hours after approval)
 * - Emergency veto by guardian council
 * - Quorum requirements and approval thresholds
 */
contract Governance is AccessControl, ReentrancyGuard {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant TIMELOCK_PERIOD = 2 days;
    uint256 public constant QUORUM_PERCENTAGE = 10; // 10% of total supply
    uint256 public constant APPROVAL_THRESHOLD = 51; // 51% approval
    
    enum ProposalState { Pending, Active, Succeeded, Defeated, Queued, Executed, Vetoed }
    
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address target;
        bytes data;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 executionTime;
        ProposalState state;
        mapping(address => bool) hasVoted;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower; // UNY token balance
    uint256 public totalVotingPower;
    
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 startBlock,
        uint256 endBlock
    );
    
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        bool support,
        uint256 weight
    );
    
    event ProposalQueued(uint256 indexed proposalId, uint256 executionTime);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalVetoed(uint256 indexed proposalId, address indexed guardian);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GUARDIAN_ROLE, msg.sender);
    }
    
    /**
     * @dev Create a new governance proposal
     * @param title Short title for the proposal
     * @param description Detailed description and rationale
     * @param target Contract address to call
     * @param data Encoded function call data
     */
    function propose(
        string memory title,
        string memory description,
        address target,
        bytes memory data
    ) external returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(target != address(0), "Invalid target address");
        require(votingPower[msg.sender] >= totalVotingPower / 100, "Insufficient voting power");
        
        uint256 proposalId = ++proposalCount;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.target = target;
        proposal.data = data;
        proposal.startBlock = block.number;
        proposal.endBlock = block.number + (VOTING_PERIOD / 12); // Assuming 12 sec blocks
        proposal.state = ProposalState.Active;
        
        emit ProposalCreated(proposalId, msg.sender, title, proposal.startBlock, proposal.endBlock);
        
        return proposalId;
    }
    
    /**
     * @dev Cast a vote on an active proposal
     * @param proposalId ID of the proposal
     * @param support true for yes, false for no
     */
    function castVote(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.number <= proposal.endBlock, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 weight = votingPower[msg.sender];
        require(weight > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }
        
        emit VoteCast(msg.sender, proposalId, support, weight);
    }
    
    /**
     * @dev Finalize a proposal after voting period ends
     * @param proposalId ID of the proposal
     */
    function finalizeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.number > proposal.endBlock, "Voting still ongoing");
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 quorum = (totalVotingPower * QUORUM_PERCENTAGE) / 100;
        
        if (totalVotes < quorum) {
            proposal.state = ProposalState.Defeated;
        } else {
            uint256 approvalPercentage = (proposal.forVotes * 100) / totalVotes;
            if (approvalPercentage >= APPROVAL_THRESHOLD) {
                proposal.state = ProposalState.Succeeded;
                proposal.executionTime = block.timestamp + TIMELOCK_PERIOD;
                emit ProposalQueued(proposalId, proposal.executionTime);
            } else {
                proposal.state = ProposalState.Defeated;
            }
        }
    }
    
    /**
     * @dev Execute a successful proposal after timelock
     * @param proposalId ID of the proposal
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal not approved");
        require(block.timestamp >= proposal.executionTime, "Timelock not expired");
        
        proposal.state = ProposalState.Executed;
        
        (bool success, ) = proposal.target.call(proposal.data);
        require(success, "Execution failed");
        
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev Emergency veto by guardian council
     * @param proposalId ID of the proposal to veto
     */
    function vetoProposal(uint256 proposalId) external onlyRole(GUARDIAN_ROLE) {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.state == ProposalState.Active || 
            proposal.state == ProposalState.Succeeded,
            "Cannot veto this proposal"
        );
        
        proposal.state = ProposalState.Vetoed;
        emit ProposalVetoed(proposalId, msg.sender);
    }
    
    /**
     * @dev Update voting power (called by UNY token contract)
     * @param account Address to update
     * @param power New voting power
     */
    function updateVotingPower(address account, uint256 power) external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalVotingPower = totalVotingPower - votingPower[account] + power;
        votingPower[account] = power;
    }
    
    /**
     * @dev Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) external view returns (
        address proposer,
        string memory title,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        ProposalState state,
        uint256 executionTime
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.state,
            proposal.executionTime
        );
    }
    
    /**
     * @dev Check if address has voted on proposal
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }
}
