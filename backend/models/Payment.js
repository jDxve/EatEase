const mongoose = require("mongoose");

// Define the Payment schema
const paymentSchema = new mongoose.Schema(
  {
    order_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order", // Assuming the Order model exists
      required: true,
    },
    customer_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer", // Assuming the Customer model exists
      required: true,
    },
    restaurant_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Restaurant", // Assuming the Restaurant model exists
      required: true,
    },
    payment_method: {
      type: String,
      enum: ["GCash", "Credit Card", "Debit Card", "Paypal", "Maya"], // Include Maya as an option
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    payment_status: {
      type: String,
      enum: ["pending", "successful", "failed", "cancelled"],
      default: "pending",
      required: true,
    },
    maya_ref_id: {
      type: String,
      required: function () {
        // Only require Maya reference ID if Maya is selected as the payment method
        return this.payment_method === "Maya";
      },
    },
    maya_checkout_url: {
      type: String,
      required: function () {
        // Only require this if Maya is used as the payment method
        return this.payment_method === "Maya";
      },
    },
    transaction_date: {
      type: Date,
      default: Date.now, // Set the default to the current date and time
      required: true,
    },
  },
  {
    timestamps: true, // Adds createdAt and updatedAt fields
  }
);

const Payment = mongoose.model("Payment", paymentSchema);
module.exports = Payment;
