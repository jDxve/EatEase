// models/passwordReset.js
const mongoose = require("mongoose");

const passwordResetSchema = new mongoose.Schema({
  email: { type: String, required: true },
  token: { type: String, required: true },
  expires: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now, expires: 3600 }, // Token expires after 1 hour
});

module.exports = mongoose.model("PasswordReset", passwordResetSchema);
