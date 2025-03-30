require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const cors = require("cors");
const User = require("./models/User");
const Restaurant = require("./models/Restaurant");

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
    process.exit(1); // Exit process on failure
  }
})();

//User Registration Route
app.post("/api/users/register", async (req, res) => {
  try {
    const { fullName, email, phone, password, role_id } = req.body;

    // Check if user already exists
    if (await User.findOne({ email })) {
      return res.status(400).json({ error: "Email already registered" });
    }

    // Hash password & create user
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

    // Return user ID along with the success message
    res.status(200).json({
      message: "Login successful!",
      userId: user._id.toString(), // Return the user ID as a string
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

    // Return user ID and customer ID along with the success message
    res.status(200).json({
      message: "Login successful!",
      userId: user._id.toString(), // Return the user ID as a string
      customerId: user._id.toString(), // Use _id as customerId
    });
  } catch (error) {
    console.error("Error in login:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

//Fetch all restaurants Route
app.get("/api/restaurants", async (req, res) => {
  try {
    const restaurants = await Restaurant.find({ status: 2 });
    res.status(200).json(restaurants);
  } catch (error) {
    console.error("Error fetching restaurants:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Fetch restaurant by ID Route
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

// ✅ Fetch all categories Route
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

// ✅ Fetch menu items by restaurant ID Route
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
// Define the generateOrderId function
function generateOrderId() {
  const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let orderId = "";
  const length = 6; // Length of the random part

  for (let i = 0; i < length; i++) {
    orderId += characters.charAt(Math.floor(Math.random() * characters.length));
  }

  orderId += Date.now(); // Append current timestamp
  return orderId;
}

// Add orders
app.post("/api/orders", async (req, res) => {
  console.log("Incoming order request:", req.body);
  try {
    const { customer_id, restaurant_id, items } = req.body;

    // Validate incoming data
    if (
      !customer_id ||
      !restaurant_id ||
      !Array.isArray(items) ||
      items.length === 0
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
      // Check for existing item
      const existingItemIndex = existingOrder.items.findIndex(
        (item) => item.menu_id.toString() === items[0].menu_id
      );

      if (existingItemIndex !== -1) {
        // If the item already exists, return an error message
        return res.status(400).json({
          error: "Item is already in the cart.",
        });
      }

      // Add new item if it doesn't exist
      existingOrder.items.push(items[0]);
      existingOrder.total_amount += items[0].price * items[0].quantity;
      await existingOrder.save();

      return res.status(200).json({
        message: "Item added to existing order",
        order: existingOrder,
      });
    }

    // Create new order if no existing order found
    const newOrderId = generateOrderId(); // Call the function to generate a new order ID
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
      pickup_time: new Date(),
    });

    const savedOrder = await newOrder.save();
    res.status(201).json({ message: "Order created", order: savedOrder });
  } catch (error) {
    console.error("Order error:", error.message); // Log the error message
    res.status(500).json({ error: "Server error", details: error.message });
  }
});
// Fetch cart
// Fetch cart
app.get("/api/orders/:customer_id", async (req, res) => {
  try {
    const { customer_id } = req.params;

    // Validate customer_id format
    if (!mongoose.Types.ObjectId.isValid(customer_id)) {
      return res.status(400).json({ error: "Invalid customer ID format" });
    }

    // Find the order for the customer
    const order = await Order.findOne({
      customer_id: new mongoose.Types.ObjectId(customer_id),
      order_stage: { $in: ["add to cart", "order checkout"] }, // Check for both stages
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
        id: item._id, // Include the item ID
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

    // Validate customer_id format
    if (!mongoose.Types.ObjectId.isValid(customer_id)) {
      return res.status(400).json({ error: "Invalid customer ID format" });
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

    // Clear the items in the order
    order.items = [];
    order.total_amount = 0; // Reset total amount
    await order.save(); // Save the updated order

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
});
//update order stage
app.put("/api/orders/:customerId", async (req, res) => {
  const { customerId } = req.params;
  const { order_stage } = req.body; // Expecting order_stage in the request body

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
      order.order_stage = order_stage; // Update the order stage
    }

    await order.save();

    res
      .status(200)
      .json({ message: "Order stage updated successfully", order });
  } catch (error) {
    console.error("Update order error:", error.message);
    res.status(500).json({ error: "Server error", details: error.message });
  }
});
module.exports = app;
// Start the server
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
