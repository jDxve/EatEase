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
    console.log("✅ MongoDB connected");
  } catch (err) {
    console.error("❌ MongoDB connection error:", err);
    process.exit(1); // Exit process on failure
  }
})();

// ✅ User Registration Route
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

// ✅ User Login Route
app.post("/api/users/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user) return res.status(400).json({ error: "User not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: "Invalid credentials" });

    res.status(200).json({ message: "Login successful!" });
  } catch (error) {
    console.error("Error in login:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Fetch all restaurants Route
app.get("/api/restaurants", async (req, res) => {
  try {
    const restaurants = await Restaurant.find({ status: 1 });
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
app.get("/api/restaurants/:id/menu", async (req, res) => {
  const restaurantId = req.params.id;
  try {
    const menuItems = await Menu.find({ restaurant_id: restaurantId });
    if (!menuItems.length) {
      return res
        .status(404)
        .json({ error: "No menu items found for this restaurant" });
    }
    res.json(menuItems);
  } catch (error) {
    console.error("Error fetching menu items:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = app;
// ✅ Start the server
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
