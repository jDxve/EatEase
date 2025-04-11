require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const cors = require("cors");
const User = require("./models/User");
const Restaurant = require("./models/Restaurant");
const Paymongo = require("paymongo-node");

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
      order_stage: "add to cart",
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
      order_stage: "add to cart",
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
    const { order_id, customer_id, restaurant_id, payment_method, amount } =
      req.body;

    // Convert string IDs to MongoDB ObjectIds
    const payment = new Payment({
      order_id: mongoose.Types.ObjectId(order_id),
      customer_id: mongoose.Types.ObjectId(customer_id),
      restaurant_id: mongoose.Types.ObjectId(restaurant_id),
      payment_method,
      amount: parseFloat(amount), // Ensure amount is a number
    });

    const savedPayment = await payment.save();

    res.status(201).json({
      success: true,
      data: savedPayment,
    });
  } catch (err) {
    console.error("Error creating payment record:", err);
    // Send more detailed error information
    res.status(500).json({
      success: false,
      error: err.message || "Failed to create payment record",
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
module.exports = app;
// Start the server
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
