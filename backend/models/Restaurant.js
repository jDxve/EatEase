const mongoose = require("mongoose");

const restaurantSchema = new mongoose.Schema({
  owner_name: { type: String, required: true }, // Add this
  //name: { type: String, required: true },
  status: { type: Number, required: true },
  address: {
    street: { type: String, required: true },
    city: { type: String, required: true },
    province: { type: String, required: true },
    zip: { type: String, required: true },
  },
  restaurant_photo: { type: String, required: true },
  contact: { type: String, required: true },
  //email: { type: String, required: true }, // Add this
  //password: { type: String, required: true }, // Add this
  operating_hours: {
    open: { type: String, required: true },
    close: { type: String, required: true },
  },
  rating: { type: Number, required: true },
  rating_count: { type: Number, required: true },
  created_at: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Restaurant", restaurantSchema);
