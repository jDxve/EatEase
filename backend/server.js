require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const { ObjectId } = mongoose.Types;
const bcrypt = require("bcrypt");
const cors = require("cors");
const User = require("./models/User");
const Restaurant = require("./models/Restaurant");
const Paymongo = require("paymongo-node");
const http = require("http");
const { Server } = require("socket.io");

const PORT = process.env.PORT || 5001;
const app = express();

app.use(express.json());
app.use(cors());

// Connect to MongoDB
(async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("MongoDB connected");
  } catch (err) {
    console.error("MongoDB connection error:", err);
    process.exit(1);
  }
})();

//User Registration Route
app.post("/api/users/register", async (req, res) => {
  try {
    const { fullName, email, phone, password, role_id } = req.body;

    if (await User.findOne({ email })) {
      return res.status(400).json({ error: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      fullName,
      email,
      phone,
      password: hashedPassword,
      role_id: role_id || 2,
    });

    await newUser.save();
    res.status(201).json({ message: "User registered successfully!" });
  } catch (error) {
    console.error("Error in registration:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

//User Login Route
app.post("/api/users/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(400).json({ error: "User  not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: "Invalid credentials" });

    res.status(200).json({
      message: "Login successful!",
      userId: user._id.toString(),
    });
  } catch (error) {
    console.error("Error in login:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/api/users/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(400).json({ error: "User  not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: "Invalid credentials" });

    res.status(200).json({
      message: "Login successful!",
      userId: user._id.toString(),
      customerId: user._id.toString(),
    });
  } catch (error) {
    console.error("Error in login:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get("/api/restaurants", async (req, res) => {
  try {
    const restaurants = await Restaurant.find({ status: 2 });
    res.status(200).json(restaurants);
  } catch (error) {
    console.error("Error fetching restaurants:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// etch restaurant by ID Route
app.get("/api/restaurants/:id", async (req, res) => {
  const restaurantId = req.params.id;
  try {
    const restaurant = await Restaurant.findById(restaurantId);
    if (!restaurant) {
      return res.status(404).json({ error: "Restaurant not found" });
    }
    res.json(restaurant);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});

const Category = require("./models/Categories");

// Fetch all categories Route
app.get("/api/categories", async (req, res) => {
  try {
    const categories = await Category.find({});
    res.status(200).json(categories);
  } catch (error) {
    console.error("Error fetching categories:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

const Menu = require("./models/Menu");

// Fetch menu items by restaurant ID Route
app.get("/api/restaurants/:restaurantId/menu", async (req, res) => {
  const { restaurantId } = req.params;

  if (!mongoose.Types.ObjectId.isValid(restaurantId)) {
    return res.status(400).json({ error: "Invalid restaurant ID format" });
  }

  try {
    const filteredMenu = await Menu.find({
      restaurant_id: new mongoose.Types.ObjectId(restaurantId),
    });

    if (!filteredMenu.length) {
      return res.status(404).json({
        restaurant_id: restaurantId,
        error: "no menu items found for this restaurant",
      });
    }

    res.status(200).json({ menu: filteredMenu });
  } catch (error) {
    console.error("Error fetching menu items:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});
const Order = require("./models/Orders");

function generateOrderId() {
  const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let orderId = "";
  const length = 6;

  for (let i = 0; i < length; i++) {
    orderId += characters.charAt(Math.floor(Math.random() * characters.length));
  }

  orderId += Date.now();
  return orderId;
}

// Add orders
// Add orders
app.post("/api/orders", async (req, res) => {
  console.log("Incoming order request:", req.body);
  try {
    const { customer_id, restaurant_id, items, pickup_time } = req.body; // Extract pickup_time from the request body

    // Validate input data
    if (
      !customer_id ||
      !restaurant_id ||
      !Array.isArray(items) ||
      items.length === 0 ||
      !pickup_time // Ensure pickup_time is provided
    ) {
      return res.status(400).json({ error: "Invalid input data" });
    }

    // Validate ObjectId formats
    if (
      !mongoose.Types.ObjectId.isValid(customer_id) ||
      !mongoose.Types.ObjectId.isValid(restaurant_id)
    ) {
      return res
        .status(400)
        .json({ error: "Invalid customer or restaurant ID format" });
    }

    // Find existing order for the customer
    const existingOrder = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customer_id),
      order_stage: "add to cart",
      order_status: 1,
    });

    if (existingOrder) {
      const existingItemIndex = existingOrder.items.findIndex(
        (item) => item.menu_id.toString() === items[0].menu_id
      );

      if (existingItemIndex !== -1) {
        return res.status(400).json({
          error: "Item is already in the cart.",
        });
      }

      existingOrder.items.push(items[0]);
      existingOrder.total_amount += items[0].price * items[0].quantity;
      await existingOrder.save();

      return res.status(200).json({
        message: "Item added to existing order",
        order: existingOrder,
      });
    }

    // Generate a new order ID
    const newOrderId = generateOrderId();
    const newOrder = new Order({
      customer_id: new mongoose.Types.ObjectId(customer_id),
      restaurant_id: new mongoose.Types.ObjectId(restaurant_id),
      order_id: newOrderId,
      items,
      total_amount: items.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      ),
      order_status: 1,
      order_stage: "add to cart",
      pickup_time: pickup_time, // Save the pickup_time from the request
    });

    const savedOrder = await newOrder.save();
    res.status(201).json({ message: "Order created", order: savedOrder });
  } catch (error) {
    console.error("Order error:", error.message);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});
// Fetch cart
app.get("/api/orders/:customer_id", async (req, res) => {
  try {
    const { customer_id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(customer_id)) {
      return res.status(400).json({ error: "Invalid customer ID format" });
    }

    const order = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customer_id),
      order_stage: { $in: ["add to cart", "order checkout"] },
      order_status: 1,
    });

    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    // Format the order response
    const formattedOrder = {
      id: order._id,
      customerId: order.customer_id,
      restaurantId: order.restaurant_id,
      items: order.items.map((item) => ({
        id: item._id,
        menuId: item.menu_id,
        image: item.image,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
      })),
      totalAmount: order.total_amount,
      orderStatus: order.order_status,
      orderStage: order.order_stage,
      pickupTime: order.pickup_time,
      createdAt: order.created_at,
    };

    res.status(200).json({ message: "Order found", order: formattedOrder });
  } catch (error) {
    console.error("Order error:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

// Delete all items in the cart for a specific user
app.delete("/api/orders/:customer_id/items", async (req, res) => {
  try {
    const { customer_id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(customer_id)) {
      return res.status(400).json({ error: "Invalid customer ID format" });
    }

    const order = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customer_id),
      order_status: 1,
    });

    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    order.items = [];
    order.total_amount = 0;
    await order.save();

    res.status(200).json({ message: "All items deleted from order", order });
  } catch (error) {
    console.error("Delete all items error:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

app.get("/api/check_active_cart/:customerId", async (req, res) => {
  try {
    const customer_id = req.params.customerId;

    const order = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customer_id),
      order_status: 1,
    });

    res.json({
      hasActiveCart: !!order, // Convert to boolean
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete("/api/orders/:customer_id/items/:item_id", async (req, res) => {
  try {
    const { customer_id, item_id } = req.params;

    // Validate customer_id format
    if (
      !mongoose.Types.ObjectId.isValid(customer_id) ||
      !mongoose.Types.ObjectId.isValid(item_id)
    ) {
      return res.status(400).json({ error: "Invalid ID format" });
    }

    // Find the order for the customer
    const order = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customer_id),
      order_stage: { $in: ["add to cart", "order checkout"] },
      order_status: 1,
    });

    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    // Find the item to delete
    const itemIndex = order.items.findIndex(
      (item) => item._id.toString() === item_id
    );
    if (itemIndex === -1) {
      return res.status(404).json({ error: "Item not found in order" });
    }

    // Remove the item from the order
    const itemPrice =
      order.items[itemIndex].price * order.items[itemIndex].quantity; // Calculate total price of the item
    order.items.splice(itemIndex, 1);
    order.total_amount -= itemPrice;

    await order.save(); // Save the updated order

    res.status(200).json({ message: "Item deleted from order", order });
  } catch (error) {
    console.error("Delete order error:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

// Add this route to your express app code (in the server file)

// Cancel order endpoint
app.put("/api/cancel_order/:orderId", async (req, res) => {
  const { orderId } = req.params;
  const { customerId } = req.body; // Assuming customerId is sent in the request body

  console.log("Cancelling Order ID:", orderId);
  console.log("Customer ID:", customerId);

  // Validate ObjectId
  if (!mongoose.Types.ObjectId.isValid(orderId)) {
    return res.status(400).json({ message: "Invalid order ID" });
  }
  if (!mongoose.Types.ObjectId.isValid(customerId)) {
    return res.status(400).json({ message: "Invalid customer ID" });
  }

  try {
    // First, find the order to make sure it exists and belongs to the customer
    const order = await Order.findOne({
      _id: orderId,
      customer_id: new mongoose.Types.ObjectId(customerId),
    });

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    // Check if the order is in a status that can be cancelled (status 1)
    if (order.order_status !== 1) {
      return res.status(400).json({
        message:
          "Cannot cancel this order. Only pending orders can be cancelled.",
      });
    }

    // Update order status to cancelled (status 0)
    const updatedOrder = await Order.findOneAndUpdate(
      {
        _id: orderId,
        customer_id: new mongoose.Types.ObjectId(customerId),
      },
      {
        order_status: 0, // Set status to 0 for cancelled
        order_stage: "order cancelled",
      },
      { new: true } // Return the updated document
    );

    res.status(200).json({
      message: "Order cancelled successfully",
      order: updatedOrder,
    });
  } catch (error) {
    console.error("Error cancelling order:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

app.get("/api/pending_orders/:customerId", async (req, res) => {
  const { customerId } = req.params;

  // Validate ObjectId
  if (!mongoose.Types.ObjectId.isValid(customerId)) {
    return res.status(400).json({ message: "Invalid customer ID" });
  }

  try {
    const pendingOrders = await Order.find({
      customer_id: new mongoose.Types.ObjectId(customerId),
      order_status: { $in: [1, 2, 3] }, // Status values for pending orders
      order_stage: "place order", // Add the order_stage check
    });

    res.status(200).json(pendingOrders);
  } catch (error) {
    console.error("Error fetching pending orders:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

// Update item quantity in an existing order
app.put("/api/orders/:customerId/items/:itemId", async (req, res) => {
  const { customerId, itemId } = req.params;
  const { quantity } = req.body;

  try {
    const order = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customerId),
      order_stage: "add to cart",
      order_status: 1,
    });

    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    const itemIndex = order.items.findIndex(
      (item) => item._id.toString() === itemId
    );
    if (itemIndex === -1) {
      return res.status(404).json({ error: "Item not found in order" });
    }

    // Update the quantity
    order.items[itemIndex].quantity = quantity;
    order.total_amount = order.items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
    await order.save();

    res.status(200).json({ message: "Item quantity updated", order });
  } catch (error) {
    console.error("Update item error:", error.message);
    res.status(500).json({ error: "Server error", details: error.message });
  }
}); // Update order stage and pickup time
app.put("/api/orders/:customerId", async (req, res) => {
  const { customerId } = req.params;
  const { order_stage, pickup_time } = req.body; // Include pickup_time in the request body

  try {
    const order = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customerId),
      order_status: 1,
    });

    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    // Update the order stage
    if (order_stage) {
      order.order_stage = order_stage;
    }

    // Update the pickup time if provided
    if (pickup_time) {
      order.pickup_time = pickup_time; // Update the pickup time
    }

    await order.save();

    res.status(200).json({ message: "Order updated successfully", order });
  } catch (error) {
    console.error("Update order error:", error.message);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

const axios = require("axios");
const PAYMONGO_SECRET_KEY = "sk_test_ud4EFbLxhHYzYPTLRQaue6wF";
const Payment = require("./models/Payment");
// Create payment based on method
app.post("/api/create-payment", async (req, res) => {
  const { amount, paymentMethod, description } = req.body;

  try {
    let response;

    if (paymentMethod === "gcash" || paymentMethod === "grab_pay") {
      // For GCash and GrabPay, create a source
      response = await axios.post(
        "https://api.paymongo.com/v1/sources",
        {
          data: {
            attributes: {
              amount: amount,
              type: paymentMethod,
              currency: "PHP",
              redirect: {
                success: "http://localhost:5001/success",
                failed: "http://localhost:5001/failed",
              },
            },
          },
        },
        {
          headers: {
            Authorization: `Basic ${Buffer.from(
              PAYMONGO_SECRET_KEY + ":"
            ).toString("base64")}`,
            "Content-Type": "application/json",
          },
        }
      );

      return res.status(201).json({
        success: true,
        data: response.data,
        checkoutUrl: response.data.data.attributes.redirect.checkout_url,
      });
    } else if (paymentMethod === "card") {
      // For card payments, create a payment intent
      response = await axios.post(
        "https://api.paymongo.com/v1/payment_intents",
        {
          data: {
            attributes: {
              amount: amount,
              payment_method_allowed: ["card"],
              payment_method_options: {
                card: { request_three_d_secure: "any" },
              },
              description: description,
              currency: "PHP",
              capture_type: "automatic",
            },
          },
        },
        {
          headers: {
            Authorization: `Basic ${Buffer.from(
              PAYMONGO_SECRET_KEY + ":"
            ).toString("base64")}`,
            "Content-Type": "application/json",
          },
        }
      );

      return res.status(201).json({
        success: true,
        data: response.data,
        clientKey: response.data.data.attributes.client_key,
      });
    } else if (paymentMethod === "paymaya") {
      // For PayMaya payments
      response = await axios.post(
        "https://api.paymongo.com/v1/links",
        {
          data: {
            attributes: {
              amount: amount,
              description: description,
              currency: "PHP",
              payment_method_allowed: ["paymaya"],
            },
          },
        },
        {
          headers: {
            Authorization: `Basic ${Buffer.from(
              PAYMONGO_SECRET_KEY + ":"
            ).toString("base64")}`,
            "Content-Type": "application/json",
          },
        }
      );

      return res.status(201).json({
        success: true,
        data: response.data,
        checkoutUrl: response.data.data.attributes.checkout_url,
      });
    }

    throw new Error("Unsupported payment method");
  } catch (err) {
    console.error("Error creating payment:", err.response?.data || err);
    res.status(500).json({
      success: false,
      error: "Failed to create payment",
      details: err.response?.data || err.message,
    });
  }
});

// Check payment status
app.get("/api/payment-status/:id", async (req, res) => {
  const { id } = req.params;
  const { type } = req.query; // 'source' or 'payment_intent'

  try {
    const endpoint =
      type === "source"
        ? `https://api.paymongo.com/v1/sources/${id}`
        : `https://api.paymongo.com/v1/payment_intents/${id}`;

    const response = await axios.get(endpoint, {
      headers: {
        Authorization: `Basic ${Buffer.from(PAYMONGO_SECRET_KEY + ":").toString(
          "base64"
        )}`,
        "Content-Type": "application/json",
      },
    });

    res.status(200).json({
      success: true,
      data: response.data,
    });
  } catch (err) {
    console.error("Error checking payment status:", err.response?.data || err);
    res.status(500).json({
      success: false,
      error: "Failed to check payment status",
      details: err.response?.data || err.message,
    });
  }
});

app.post("/api/payments", async (req, res) => {
  try {
    const { customer_id, restaurant_id, payment_method, amount } = req.body;

    // Validate required fields
    if (!customer_id || !restaurant_id || !payment_method || !amount) {
      return res.status(400).json({
        success: false,
        error: "Missing required fields",
      });
    }

    // Create new payment document
    const payment = new Payment({
      customer_id: new ObjectId(customer_id),
      restaurant_id: new ObjectId(restaurant_id),
      payment_method,
      amount: parseFloat(amount),
      transaction_date: new Date(),
    });

    const savedPayment = await payment.save();

    res.status(201).json({
      success: true,
      data: savedPayment,
    });
  } catch (err) {
    console.error("Error creating payment record:", err);
    res.status(500).json({
      success: false,
      error: err.message || "Failed to create payment record",
    });
  }
});

// Add a route to get payment details by order ID
app.get("/api/payments/order/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      return res.status(400).json({
        success: false,
        error: "Invalid order ID format",
      });
    }

    const payment = await Payment.findOne({ order_id: new ObjectId(orderId) });

    if (!payment) {
      return res.status(404).json({
        success: false,
        error: "Payment not found for this order",
      });
    }

    res.status(200).json({
      success: true,
      data: payment,
    });
  } catch (err) {
    console.error("Error fetching payment record:", err);
    res.status(500).json({
      success: false,
      error: err.message || "Failed to fetch payment record",
    });
  }
});

// Add a route to get payment details by order ID
app.get("/api/payments/order/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      return res.status(400).json({
        success: false,
        error: "Invalid order ID format",
      });
    }

    const payment = await Payment.findOne({ order_id: new ObjectId(orderId) });

    if (!payment) {
      return res.status(404).json({
        success: false,
        error: "Payment not found for this order",
      });
    }

    res.status(200).json({
      success: true,
      data: payment,
    });
  } catch (err) {
    console.error("Error fetching payment record:", err);
    res.status(500).json({
      success: false,
      error: err.message || "Failed to fetch payment record",
    });
  }
});

// Fetch orders with specific stage and status
app.get("/api/place_orders/:userId", async (req, res) => {
  try {
    const { userId } = req.params; // Change from customer_id to userId to match route parameter

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    const orders = await Order.find({
      // Change from findOne to find to get all orders
      customer_id: new mongoose.Types.ObjectId(userId),
      order_stage: "place order",
      order_status: { $in: [1, 2, 3] },
    }).sort({ createdAt: -1 }); // Sort by newest first

    if (!orders || orders.length === 0) {
      return res.status(404).json({ message: "No orders found for this user" });
    }

    // Format the orders response
    const formattedOrders = orders.map((order) => ({
      id: order._id,
      order_id: order.order_id,
      customerId: order.customer_id,
      restaurantId: order.restaurant_id,
      items: order.items.map((item) => ({
        id: item._id,
        menuId: item.menu_id,
        image: item.image,
        name: item.name,
        quantity: parseInt(item.quantity),
        price: parseFloat(item.price),
      })),
      totalAmount: order.total_amount,
      orderStatus: order.order_status,
      orderStage: order.order_stage,
      pickupTime: order.pickup_time,
      createdAt: order.createdAt,
    }));

    res.status(200).json(formattedOrders);
  } catch (error) {
    console.error("Order error:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

// Get completed orders for a user
app.get("/api/orders/:userId/completed", async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    const orders = await Order.find({
      customer_id: new mongoose.Types.ObjectId(userId),
      order_status: 4, // Completed orders
    }).sort({ createdAt: -1 });

    if (!orders || orders.length === 0) {
      return res.status(404).json({ message: "No completed orders found" });
    }

    res.status(200).json(orders);
  } catch (error) {
    console.error("Error fetching completed orders:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

// Rate an order
app.post("/api/orders/:orderId/rate", async (req, res) => {
  try {
    const { orderId } = req.params;
    const { rating, userId } = req.body;

    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      return res.status(400).json({ error: "Invalid order ID format" });
    }

    const order = await Order.findOneAndUpdate(
      {
        _id: orderId,
        customer_id: userId,
        order_status: 4, // Only allow rating completed orders
      },
      { rating: rating },
      { new: true }
    );

    if (!order) {
      return res
        .status(404)
        .json({ error: "Order not found or cannot be rated" });
    }

    res.status(200).json({ message: "Rating updated successfully", order });
  } catch (error) {
    console.error("Rating error:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});

// Update order status endpoint
// Update order status endpoint
app.put("/api/update_order/:orderId", async (req, res) => {
  const { orderId } = req.params;
  const { customerId } = req.body; // Assuming customerId is sent in the request body

  console.log("Order ID:", orderId);
  console.log("Customer ID:", customerId);

  // Validate ObjectId
  if (!mongoose.Types.ObjectId.isValid(orderId)) {
    return res.status(400).json({ message: "Invalid order ID" });
  }
  if (!mongoose.Types.ObjectId.isValid(customerId)) {
    return res.status(400).json({ message: "Invalid customer ID" });
  }

  try {
    const updatedOrder = await Order.findOneAndUpdate(
      {
        _id: orderId,
        customer_id: new mongoose.Types.ObjectId(customerId), // Check customer ID
      },
      {
        order_stage: "order already picked up",
        order_status: 4,
      },
      { new: true } // Return the updated document
    );

    if (!updatedOrder) {
      return res.status(404).json({ message: "Order not found" });
    }

    res.status(200).json({
      message: "Order updated successfully",
      order: updatedOrder,
    });
  } catch (error) {
    console.error("Error updating order:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});
// GET /api/users/:id - Get user data by ID
app.get("/api/users/:id", async (req, res) => {
  const userId = req.params.id;

  try {
    const user = await User.findById(userId); // Do not exclude password
    if (!user) {
      return res.status(404).json({ error: "User  not found" });
    }

    // Format the user object to a more friendly format
    const formattedUser = {
      id: user._id.toString(), // Convert ObjectId to string
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role_id: user.role_id,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };

    res.json(formattedUser);
  } catch (error) {
    console.error("Error fetching user:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// GET /api/restaurants/:restaurantId
app.get("/api/restaurants/:restaurantId", async (req, res) => {
  try {
    const { restaurantId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(restaurantId)) {
      return res.status(400).json({ error: "Invalid restaurant ID format" });
    }

    const restaurant = await Restaurant.findById(restaurantId); // Assuming your Restaurant model is named "Restaurant"

    if (!restaurant) {
      return res.status(404).json({ message: "Restaurant not found" });
    }

    // Send back only the name and restaurant_photo
    const { name, restaurant_photo } = restaurant;
    res.status(200).json({ name, restaurant_photo });
  } catch (error) {
    console.error("Error fetching restaurant:", error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});
//upate user data
app.put("/api/users/:id", async (req, res) => {
  const userId = req.params.id;
  const { fullName, email, phone } = req.body;

  try {
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { fullName, email, phone },
      { new: true, runValidators: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: "User not found" });
    }

    res
      .status(200)
      .json({ message: "User updated successfully", user: updatedUser });
  } catch (error) {
    console.error("Error updating user:", error.message);
    res.status(500).json({ error: error.message });
  }
});

const Chat = require("./models/Chat");

// --- Socket.IO Setup ---
const server = http.createServer(app);
// Socket.IO setup with CORS
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// Socket.IO connection handling
io.on("connection", (socket) => {
  console.log("Client connected:", socket.id);

  socket.on("joinChat", (data) => {
    const chatId = data.chatId;
    socket.join(chatId);
    console.log(`Client ${socket.id} joined chat: ${chatId}`);
  });

  socket.on("sendMessage", async (data) => {
    try {
      const { chatId, sender_id, message, timestamp } = data;

      // Save message to database
      const chat = await Chat.findById(chatId);
      if (chat) {
        chat.messages.push({
          sender_id,
          message,
          timestamp: new Date(timestamp),
        });
        await chat.save();

        // Broadcast to all clients in the room (including sender)
        io.in(chatId).emit("messageReceived", {
          sender_id,
          message,
          timestamp,
        });
      }
    } catch (error) {
      console.error("Error handling message:", error);
      socket.emit("error", { message: "Failed to process message" });
    }
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});
// Create a new chat
app.post("/api/chats", async (req, res) => {
  const { customer_id, restaurant_id } = req.body;

  try {
    const existingChat = await Chat.findOne({
      $or: [
        { customer_id, restaurant_id },
        { customer_id: restaurant_id, restaurant_id: customer_id },
      ],
    });

    if (existingChat) {
      return res.status(200).json(existingChat);
    } else {
      const newChat = new Chat({
        customer_id,
        restaurant_id,
        messages: [],
        last_updated: new Date(),
      });

      const savedChat = await newChat.save();
      res.status(201).json(savedChat);
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Send a message
app.post("/api/chats/:chatId/messages", async (req, res) => {
  const { chatId } = req.params;
  const { sender_id, message } = req.body;

  try {
    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ message: "Chat not found" });
    }

    const newMessage = {
      sender_id,
      message,
      timestamp: new Date(),
      seen: false,
    };

    chat.messages.push(newMessage);
    chat.last_updated = new Date();
    await chat.save();

    // Emit the new message to all clients in the chat
    io.to(chatId).emit("messageReceived", newMessage);

    res.status(200).json(chat);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Endpoint to get chat by user ID and restaurant ID
app.get(
  "/api/chats/users/:userId/restaurants/:restaurantId",
  async (req, res) => {
    const { userId, restaurantId } = req.params;

    try {
      const chat = await Chat.findOne({
        customer_id: userId,
        restaurant_id: restaurantId,
      });
      if (!chat) {
        return res.status(404).json({ message: "Chat not found" });
      }
      res.json(chat);
    } catch (error) {
      res.status(500).json({ message: "Server error", error });
    }
  }
);

// Get chat by ID
app.get("/api/chats/:chatId/messages", async (req, res) => {
  const { chatId } = req.params;

  try {
    const chat = await Chat.findById(chatId).populate("messages.sender_id");
    if (!chat) {
      return res.status(404).json({ message: "Chat not found" });
    }
    res.status(200).json(chat.messages);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Fetch all chats for a user
app.get("/api/users/:userId/chats", async (req, res) => {
  const { userId } = req.params;

  try {
    const chats = await Chat.find({
      $or: [{ customer_id: userId }, { restaurant_id: userId }],
    }).populate("messages.sender_id");

    if (!chats.length) {
      return res.status(404).json({ message: "No chats found for this user" });
    }

    res.status(200).json(chats);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Fetch all contacts for a user
app.get("/api/users/:userId/contacts", async (req, res) => {
  const { userId } = req.params;

  try {
    // Find all chats where the user is either customer or restaurant
    const chats = await Chat.find({
      $or: [{ customer_id: userId }, { restaurant_id: userId }],
    })
      .populate("restaurant_id", "name") // Populate restaurant details
      .populate("customer_id", "name") // Populate customer details
      .sort({ last_updated: -1 }); // Sort by most recent

    if (!chats.length) {
      return res.status(200).json({ contacts: [] });
    }

    // Format the response
    const contacts = chats.map((chat) => {
      const lastMessage =
        chat.messages.length > 0
          ? chat.messages[chat.messages.length - 1]
          : null;
      const isCustomer = chat.customer_id._id.toString() === userId;

      return {
        chatId: chat._id,
        contactId: isCustomer ? chat.restaurant_id._id : chat.customer_id._id,
        contactName: isCustomer
          ? chat.restaurant_id.name
          : chat.customer_id.name,
        lastMessage: lastMessage ? lastMessage.message : "",
        lastMessageTime: lastMessage
          ? lastMessage.timestamp
          : chat.last_updated,
        unreadCount: chat.messages.filter(
          (msg) => !msg.seen && msg.sender_id.toString() !== userId
        ).length,
      };
    });

    res.status(200).json({ contacts });
  } catch (error) {
    console.error("Error fetching contacts:", error);
    res.status(500).json({
      message: "Error fetching contacts",
      error: error.message,
    });
  }
});

const nodemailer = require("nodemailer");
const crypto = require("crypto");
const PasswordReset = require("./models/passwordReset");

// Configure nodemailer transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  host: "smtp.gmail.com",
  port: 587,
  secure: false,
  auth: {
    user: "eatease9@gmail.com", // Direct email
    pass: "axfc tvhb bhgy ngkt", // Direct app password
  },
  tls: {
    rejectUnauthorized: false,
  },
});

// Verify transporter
transporter.verify((error, success) => {
  if (error) {
    console.error("Transporter verification error:", error);
  } else {
    console.log("Email transporter is ready");
  }
});

// Generate 6-digit code
function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Request verification code route
app.post("/api/auth/request-verification-code", async (req, res) => {
  try {
    const { email } = req.body;
    console.log("Request received for email:", email);

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const verificationCode = generateVerificationCode();
    console.log("Generated code:", verificationCode);

    // Save to database
    await PasswordReset.findOneAndUpdate(
      { email },
      {
        email,
        code: verificationCode,
        expires: new Date(Date.now() + 600000), // 10 minutes
        verified: false,
      },
      { upsert: true, new: true }
    );

    // Send email
    const mailOptions = {
      from: {
        name: "EatEase",
        address: "eatease9@gmail.com",
      },
      to: email,
      subject: "Password Reset Verification Code",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #FF4444;">Password Reset Verification Code</h2>
          <p>Your verification code is:</p>
          <div style="background-color: #f4f4f4; padding: 15px; text-align: center; font-size: 24px; letter-spacing: 5px; margin: 20px 0;">
            <strong>${verificationCode}</strong>
          </div>
          <p>This code will expire in 10 minutes.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("Verification email sent successfully");

    res.status(200).json({ message: "Verification code sent successfully" });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Failed to send verification code" });
  }
});

// Verify code route
app.post("/api/auth/verify-code", async (req, res) => {
  try {
    const { email, code } = req.body;

    const resetRequest = await PasswordReset.findOne({
      email,
      code,
      expires: { $gt: Date.now() },
    });

    if (!resetRequest) {
      return res.status(400).json({ error: "Invalid or expired code" });
    }

    resetRequest.verified = true;
    await resetRequest.save();

    res.status(200).json({ message: "Code verified successfully" });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Failed to verify code" });
  }
});

// Reset password route
app.post("/api/auth/reset-password", async (req, res) => {
  try {
    const { email, code, new_password } = req.body;

    const resetRequest = await PasswordReset.findOne({
      email,
      code,
      verified: true,
      expires: { $gt: Date.now() },
    });

    if (!resetRequest) {
      return res.status(400).json({ error: "Invalid or expired code" });
    }

    const hashedPassword = await bcrypt.hash(new_password, 10);
    await User.findOneAndUpdate({ email }, { password: hashedPassword });

    await PasswordReset.deleteOne({ _id: resetRequest._id });

    res.status(200).json({ message: "Password reset successful" });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Failed to reset password" });
  }
});

module.exports = app;
// Start the server
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
