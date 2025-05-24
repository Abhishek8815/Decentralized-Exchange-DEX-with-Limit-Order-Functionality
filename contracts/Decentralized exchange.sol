// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LimitOrderDEX {
    struct Order {
        address trader;
        address tokenGet;   // Token buyer wants to get
        uint256 amountGet;
        address tokenGive;  // Token buyer wants to give
        uint256 amountGive;
        uint256 timestamp;
        bool filled;
        bool canceled;
    }

    uint256 public nextOrderId;
    mapping(uint256 => Order) public orders;

    event OrderCreated(
        uint256 indexed orderId,
        address indexed trader,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    event OrderFilled(uint256 indexed orderId, address indexed filler);
    event OrderCanceled(uint256 indexed orderId);

    // Create a new limit order
    function createOrder(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive
    ) external returns (uint256) {
        require(amountGet > 0 && amountGive > 0, "Amounts must be greater than zero");
        require(tokenGet != address(0) && tokenGive != address(0), "Invalid token address");

        // User must have approved tokenGive amount to this contract prior to this call
        require(IERC20(tokenGive).transferFrom(msg.sender, address(this), amountGive), "Transfer of tokens failed");

        orders[nextOrderId] = Order({
            trader: msg.sender,
            tokenGet: tokenGet,
            amountGet: amountGet,
            tokenGive: tokenGive,
            amountGive: amountGive,
            timestamp: block.timestamp,
            filled: false,
            canceled: false
        });

        emit OrderCreated(nextOrderId, msg.sender, tokenGet, amountGet, tokenGive, amountGive, block.timestamp);

        nextOrderId++;
        return nextOrderId - 1;
    }

    // Fill an existing order
    function fillOrder(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(!order.filled, "Order already filled");
        require(!order.canceled, "Order canceled");
        require(order.trader != address(0), "Order does not exist");

        // Transfer tokenGet from filler to order.trader
        require(IERC20(order.tokenGet).transferFrom(msg.sender, order.trader, order.amountGet), "Payment transfer failed");

        // Transfer tokenGive from contract to filler
        require(IERC20(order.tokenGive).transfer(msg.sender, order.amountGive), "Token delivery failed");

        order.filled = true;

        emit OrderFilled(orderId, msg.sender);
    }

    // Cancel an order and refund tokenGive to trader
    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(order.trader == msg.sender, "Only trader can cancel");
        require(!order.filled, "Order already filled");
        require(!order.canceled, "Order already canceled");

        order.canceled = true;

        // Refund tokenGive to trader
        require(IERC20(order.tokenGive).transfer(order.trader, order.amountGive), "Refund failed");

        emit OrderCanceled(orderId);
    }

    // Get order details
    function getOrder(uint256 orderId) external view returns (
        address trader,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp,
        bool filled,
        bool canceled
    ) {
        Order storage order = orders[orderId];
        return (
            order.trader,
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive,
            order.timestamp,
            order.filled,
            order.canceled
        );
    }
}
