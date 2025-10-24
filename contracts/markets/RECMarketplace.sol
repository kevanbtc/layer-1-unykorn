// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title RECMarketplace
 * @notice Spot market for renewable energy certificates
 * @dev Orderbook with maker/taker matching
 */
contract RECMarketplace is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    struct Order {
        address maker;
        address recToken;      // ERC1155REC contract
        uint256 tokenId;
        uint256 amount;
        uint256 pricePerUnit;  // USD (scaled by 10^6)
        uint64 expiry;
        bool isBuy;           // true=buy order, false=sell order
        bool active;
    }
    
    Order[] public orders;
    
    // Maker => order IDs
    mapping(address => uint256[]) public ordersByMaker;
    
    uint256 public takerFeeBps = 25;  // 0.25%
    uint256 public makerFeeBps = 10;  // 0.10%
    
    address public feeCollector;
    
    event OrderCreated(
        uint256 indexed orderId,
        address indexed maker,
        address recToken,
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerUnit,
        bool isBuy
    );
    event OrderFilled(uint256 indexed orderId, address indexed taker, uint256 amount, uint256 totalPrice);
    event OrderCanceled(uint256 indexed orderId);
    event FeesUpdated(uint256 takerFeeBps, uint256 makerFeeBps);
    
    constructor(address _feeCollector) {
        require(_feeCollector != address(0), "Invalid fee collector");
        feeCollector = _feeCollector;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }
    
    /**
     * @notice Create sell order
     * @param recToken REC token contract
     * @param tokenId Token ID
     * @param amount Amount to sell
     * @param pricePerUnit Price per unit (USD, scaled by 10^6)
     * @param expiry Order expiry (Unix timestamp)
     * @return orderId New order ID
     */
    function createSellOrder(
        address recToken,
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerUnit,
        uint64 expiry
    ) external nonReentrant returns (uint256) {
        require(amount > 0, "Invalid amount");
        require(pricePerUnit > 0, "Invalid price");
        require(expiry > block.timestamp, "Invalid expiry");
        
        // Transfer RECs to marketplace
        IERC1155(recToken).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        
        uint256 orderId = orders.length;
        orders.push(Order({
            maker: msg.sender,
            recToken: recToken,
            tokenId: tokenId,
            amount: amount,
            pricePerUnit: pricePerUnit,
            expiry: expiry,
            isBuy: false,
            active: true
        }));
        
        ordersByMaker[msg.sender].push(orderId);
        
        emit OrderCreated(orderId, msg.sender, recToken, tokenId, amount, pricePerUnit, false);
        
        return orderId;
    }
    
    /**
     * @notice Create buy order (deposit USD stablecoin)
     * @param recToken REC token contract
     * @param tokenId Token ID
     * @param amount Amount to buy
     * @param pricePerUnit Price per unit (USD, scaled by 10^6)
     * @param expiry Order expiry (Unix timestamp)
     * @return orderId New order ID
     */
    function createBuyOrder(
        address recToken,
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerUnit,
        uint64 expiry
    ) external payable nonReentrant returns (uint256) {
        require(amount > 0, "Invalid amount");
        require(pricePerUnit > 0, "Invalid price");
        require(expiry > block.timestamp, "Invalid expiry");
        
        uint256 totalCost = amount * pricePerUnit;
        require(msg.value >= totalCost, "Insufficient payment");
        
        // Refund excess
        if (msg.value > totalCost) {
            (bool success, ) = msg.sender.call{value: msg.value - totalCost}("");
            require(success, "Refund failed");
        }
        
        uint256 orderId = orders.length;
        orders.push(Order({
            maker: msg.sender,
            recToken: recToken,
            tokenId: tokenId,
            amount: amount,
            pricePerUnit: pricePerUnit,
            expiry: expiry,
            isBuy: true,
            active: true
        }));
        
        ordersByMaker[msg.sender].push(orderId);
        
        emit OrderCreated(orderId, msg.sender, recToken, tokenId, amount, pricePerUnit, true);
        
        return orderId;
    }
    
    /**
     * @notice Fill sell order (buy RECs)
     * @param orderId Order ID
     * @param amount Amount to buy
     */
    function fillSellOrder(uint256 orderId, uint256 amount) external payable nonReentrant {
        require(orderId < orders.length, "Invalid order");
        Order storage order = orders[orderId];
        
        require(order.active, "Order not active");
        require(!order.isBuy, "Not a sell order");
        require(block.timestamp <= order.expiry, "Order expired");
        require(amount > 0 && amount <= order.amount, "Invalid amount");
        
        uint256 totalPrice = amount * order.pricePerUnit;
        uint256 takerFee = (totalPrice * takerFeeBps) / 10000;
        uint256 makerFee = (totalPrice * makerFeeBps) / 10000;
        
        require(msg.value >= totalPrice + takerFee, "Insufficient payment");
        
        // Transfer RECs to taker
        IERC1155(order.recToken).safeTransferFrom(
            address(this),
            msg.sender,
            order.tokenId,
            amount,
            ""
        );
        
        // Pay maker
        (bool success, ) = order.maker.call{value: totalPrice - makerFee}("");
        require(success, "Payment failed");
        
        // Collect fees
        (success, ) = feeCollector.call{value: takerFee + makerFee}("");
        require(success, "Fee collection failed");
        
        // Update order
        order.amount -= amount;
        if (order.amount == 0) {
            order.active = false;
        }
        
        // Refund excess
        if (msg.value > totalPrice + takerFee) {
            (success, ) = msg.sender.call{value: msg.value - totalPrice - takerFee}("");
            require(success, "Refund failed");
        }
        
        emit OrderFilled(orderId, msg.sender, amount, totalPrice);
    }
    
    /**
     * @notice Cancel order
     * @param orderId Order ID
     */
    function cancelOrder(uint256 orderId) external nonReentrant {
        require(orderId < orders.length, "Invalid order");
        Order storage order = orders[orderId];
        
        require(order.active, "Order not active");
        require(order.maker == msg.sender || hasRole(OPERATOR_ROLE, msg.sender), "Unauthorized");
        
        order.active = false;
        
        if (!order.isBuy) {
            // Return RECs to maker
            IERC1155(order.recToken).safeTransferFrom(
                address(this),
                order.maker,
                order.tokenId,
                order.amount,
                ""
            );
        } else {
            // Return funds to maker
            uint256 refund = order.amount * order.pricePerUnit;
            (bool success, ) = order.maker.call{value: refund}("");
            require(success, "Refund failed");
        }
        
        emit OrderCanceled(orderId);
    }
    
    /**
     * @notice Set fees
     * @param _takerFeeBps Taker fee in basis points
     * @param _makerFeeBps Maker fee in basis points
     */
    function setFees(uint256 _takerFeeBps, uint256 _makerFeeBps) external onlyRole(ADMIN_ROLE) {
        require(_takerFeeBps <= 500 && _makerFeeBps <= 500, "Fees too high");
        takerFeeBps = _takerFeeBps;
        makerFeeBps = _makerFeeBps;
        emit FeesUpdated(_takerFeeBps, _makerFeeBps);
    }
    
    /**
     * @notice Set fee collector
     * @param _feeCollector New fee collector address
     */
    function setFeeCollector(address _feeCollector) external onlyRole(ADMIN_ROLE) {
        require(_feeCollector != address(0), "Invalid address");
        feeCollector = _feeCollector;
    }
    
    /**
     * @notice Get orders for maker
     * @param maker Maker address
     * @return Array of order IDs
     */
    function getOrdersByMaker(address maker) external view returns (uint256[] memory) {
        return ordersByMaker[maker];
    }
    
    /**
     * @notice Get order count
     * @return Count
     */
    function getOrderCount() external view returns (uint256) {
        return orders.length;
    }
    
    /**
     * @notice Required for receiving ERC1155 tokens
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
    
    /**
     * @notice Required for receiving batch ERC1155 tokens
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
