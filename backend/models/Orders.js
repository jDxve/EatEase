const mongoose = require("mongoose");

const orderSchema = new mongoose.Schema({
  customer_id: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: "User",
  },
  restaurant_id: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: "Restaurant",
  },
  order_id: {
    type: String,
    unique: true,
    required: true,
  },
  items: [
    {
      _id: { type: mongoose.Schema.Types.ObjectId, auto: true },
      menu_id: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "Menu",
      },
      image: { type: String, required: true },
      name: { type: String, required: true },
      quantity: { type: Number, required: true, min: 1 },
      price: { type: Number, required: true },
    },
  ],
  total_amount: { type: Number, required: true },
  order_status: {
    type: Number,
    required: true,
  },
  order_stage: {
    type: String,
    enum: ["add to cart", "order checkout", "order already pickup"],
    default: "add to cart",
  },
  pickup_time: {
    type: Date,
    default: Date.now,
  },
  preparation_status: { type: String },
  created_at: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Order", orderSchema);
