const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema({
  order_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  customer_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  restaurant_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  payment_method: { type: String, required: true },
  amount: { type: Number, required: true },
  transaction_date: { type: Date, default: Date.now },
});

const Payment = mongoose.model("Payment", paymentSchema);
module.exports = Payment;
