// models/Orders.js
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
  items: [
    {
      menu_id: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "Menu",
      },
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

// Method to update order stage
orderSchema.methods.updateOrderStage = function (newStage) {
  const validStages = ["add to cart", "order checkout", "order already pickup"];
  if (validStages.includes(newStage)) {
    this.order_stage = newStage;
    return this.save();
  } else {
    throw new Error("Invalid order stage");
  }
};

module.exports = mongoose.model("Order", orderSchema);
