const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const paymentSchema = new Schema(
  {
    customer_id: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    restaurant_id: {
      type: Schema.Types.ObjectId,
      ref: "Restaurant",
      required: true,
    },
    payment_method: {
      type: String,
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    transaction_date: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

const Payment = mongoose.model("Payment", paymentSchema);
module.exports = Payment;
