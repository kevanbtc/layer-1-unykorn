// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FeeRouter
 * @notice Routes fees from token operations to RoyaltySplitter
 * @dev Called by token contracts on mint/transfer/retire events
 */
contract FeeRouter is Ownable {
    address public royaltySplitter;
    
    mapping(bytes32 => uint16) public eventFeeBps; // Event type => fee in basis points
    
    uint256 public totalFeesCollected;
    
    event FeeCollected(bytes32 indexed eventType, address indexed payer, uint256 amount);
    event RoyaltySplitterUpdated(address newSplitter);
    event EventFeeUpdated(bytes32 indexed eventType, uint16 feeBps);
    
    constructor(address _royaltySplitter) Ownable(msg.sender) {
        require(_royaltySplitter != address(0), "Invalid splitter");
        royaltySplitter = _royaltySplitter;
    }
    
    /**
     * @notice Set royalty splitter address
     * @param newSplitter New splitter contract
     */
    function setRoyaltySplitter(address newSplitter) external onlyOwner {
        require(newSplitter != address(0), "Invalid address");
        royaltySplitter = newSplitter;
        emit RoyaltySplitterUpdated(newSplitter);
    }
    
    /**
     * @notice Set fee for event type
     * @param eventType Event identifier (e.g., keccak256("ISSUANCE"))
     * @param feeBps Fee in basis points (100 = 1%)
     */
    function setEventFee(bytes32 eventType, uint16 feeBps) external onlyOwner {
        require(feeBps <= 10000, "Fee too high");
        eventFeeBps[eventType] = feeBps;
        emit EventFeeUpdated(eventType, feeBps);
    }
    
    /**
     * @notice Calculate fee for amount
     * @param eventType Event type
     * @param baseAmount Base amount to calculate fee on
     * @return Fee amount
     */
    function calculateFee(bytes32 eventType, uint256 baseAmount) public view returns (uint256) {
        return (baseAmount * eventFeeBps[eventType]) / 10000;
    }
    
    /**
     * @notice Collect and forward fee to splitter
     * @param eventType Event type
     */
    function takeCut(bytes32 eventType) external payable {
        require(msg.value > 0, "No fee");
        
        totalFeesCollected += msg.value;
        emit FeeCollected(eventType, msg.sender, msg.value);
        
        // Forward to splitter
        (bool success, ) = royaltySplitter.call{value: msg.value}("");
        require(success, "Forward failed");
    }
}
