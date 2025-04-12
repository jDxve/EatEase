const mongoose = require("mongoose");
const Schema = mongoose.Schema;

// Define the message schema
const messageSchema = new Schema({
  sender_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Customer", // or "User " depending on your application
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  timestamp: {
    type: Date,
    required: true,
  },
  seen: {
    type: Boolean,
    default: false,
  },
});

// Define the chat schema
const chatSchema = new Schema({
  customer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Customer",
    required: true,
  },
  restaurant_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Restaurant",
    required: true,
  },
  messages: [messageSchema],
  last_updated: {
    type: Date,
    required: true,
  },
});

// Create the Chat model
const Chat = mongoose.model("Chat", chatSchema);

module.exports = Chat;
