require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const bcrypt = require("bcrypt");
const cors = require("cors"); // Import CORS
const User = require("./models/User"); // Adjust the path as necessary

const PORT = process.env.PORT || 5001;
const app = express();
app.use(bodyParser.json());
app.use(cors()); // Enable CORS for API calls

// Connect to MongoDB
mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("✅ MongoDB connected"))
  .catch((err) => console.error("❌ MongoDB connection error:", err));

// User Registration Route
app.post("/api/users/register", async (req, res) => {
  const { fullName, email, phone, password } = req.body;

  try {
    // Check if the user already exists
    const existingUser  = await User.findOne({ email });
    if (existingUser ) {
      return res.status(400).json({ error: "Email already registered" });
    }

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser  = new User({
      fullName,
      email,
      phone,
      password: hashedPassword,
    });

    await newUser .save();
    res.status(201).json({ message: "User  registered successfully!" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// User Login Route
app.post("/api/users/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find the user by email
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ error: "User  not found" });

    // Check if the password is correct
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ error: "Invalid credentials" });

    // Successful login
    res.status(200).json({ message: "Login successful!" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});



// Start the server
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));