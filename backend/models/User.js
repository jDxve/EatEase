const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String, required: true },
    password: { type: String, required: true },
    role_id: { type: Number, default: 2 },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Users", userSchema);
