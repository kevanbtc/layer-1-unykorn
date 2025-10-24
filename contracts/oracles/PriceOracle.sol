// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PriceOracle
 * @notice Real-time pricing for RECs, carbon credits, and energy
 * @dev Multi-feed oracle with staleness checks and circuit breakers
 */
contract PriceOracle is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    struct PriceFeed {
        uint128 price;        // Price in USD (scaled by PRICE_DECIMALS)
        uint64 updatedAt;     // Last update timestamp
        uint64 heartbeat;     // Max seconds between updates
        bool active;
    }
    
    // Asset type => Price feed
    mapping(bytes32 => PriceFeed) public feeds;
    
    // Circuit breaker: max price change per update
    uint16 public maxChangePercent = 5000; // 50% (in basis points)
    
    uint8 public constant PRICE_DECIMALS = 6; // $1.00 = 1_000_000
    
    event PriceUpdated(bytes32 indexed assetType, uint128 price, uint64 timestamp);
    event FeedConfigured(bytes32 indexed assetType, uint64 heartbeat, bool active);
    event CircuitBreakerTriggered(bytes32 indexed assetType, uint128 oldPrice, uint128 newPrice);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }
    
    /**
     * @notice Configure price feed
     * @param assetType Asset identifier (e.g., keccak256("REC_SOLAR_MA"))
     * @param heartbeat Max seconds between updates
     * @param active Enable/disable feed
     */
    function configureFeed(bytes32 assetType, uint64 heartbeat, bool active) external onlyRole(ADMIN_ROLE) {
        require(heartbeat > 0, "Invalid heartbeat");
        
        feeds[assetType].heartbeat = heartbeat;
        feeds[assetType].active = active;
        
        emit FeedConfigured(assetType, heartbeat, active);
    }
    
    /**
     * @notice Update price (with circuit breaker)
     * @param assetType Asset identifier
     * @param price New price (scaled by PRICE_DECIMALS)
     */
    function updatePrice(bytes32 assetType, uint128 price) external onlyRole(ORACLE_ROLE) {
        require(feeds[assetType].active, "Feed not active");
        require(price > 0, "Invalid price");
        
        uint128 oldPrice = feeds[assetType].price;
        
        // Circuit breaker check (skip if first update)
        if (oldPrice > 0) {
            uint128 diff = oldPrice > price ? oldPrice - price : price - oldPrice;
            uint256 changePercent = (uint256(diff) * 10000) / oldPrice;
            
            if (changePercent > maxChangePercent) {
                emit CircuitBreakerTriggered(assetType, oldPrice, price);
                revert("Price change too large");
            }
        }
        
        feeds[assetType].price = price;
        feeds[assetType].updatedAt = uint64(block.timestamp);
        
        emit PriceUpdated(assetType, price, uint64(block.timestamp));
    }
    
    /**
     * @notice Get latest price (reverts if stale)
     * @param assetType Asset identifier
     * @return price Latest price
     * @return updatedAt Last update timestamp
     */
    function getPrice(bytes32 assetType) external view returns (uint128 price, uint64 updatedAt) {
        PriceFeed memory feed = feeds[assetType];
        
        require(feed.active, "Feed not active");
        require(feed.price > 0, "No price data");
        require(block.timestamp - feed.updatedAt <= feed.heartbeat, "Price stale");
        
        return (feed.price, feed.updatedAt);
    }
    
    /**
     * @notice Get latest price (returns 0 if stale or inactive)
     * @param assetType Asset identifier
     * @return price Latest price (0 if unavailable)
     * @return updatedAt Last update timestamp
     */
    function tryGetPrice(bytes32 assetType) external view returns (uint128 price, uint64 updatedAt) {
        PriceFeed memory feed = feeds[assetType];
        
        if (!feed.active || feed.price == 0) {
            return (0, 0);
        }
        
        if (block.timestamp - feed.updatedAt > feed.heartbeat) {
            return (0, feed.updatedAt);
        }
        
        return (feed.price, feed.updatedAt);
    }
    
    /**
     * @notice Set circuit breaker threshold
     * @param newMaxChangePercent Max price change in basis points (5000 = 50%)
     */
    function setCircuitBreaker(uint16 newMaxChangePercent) external onlyRole(ADMIN_ROLE) {
        require(newMaxChangePercent > 0 && newMaxChangePercent <= 10000, "Invalid percent");
        maxChangePercent = newMaxChangePercent;
    }
}
