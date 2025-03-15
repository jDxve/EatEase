const mongoose = require("mongoose");

const menuSchema = new mongoose.Schema({
  restaurant_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Restaurant",
    required: true,
  },
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true, min: 0 },
  image_url: { type: String, required: true },
  availability_id: { type: Number, required: true },
  category_id: { type: Number, required: true },
  rating: { type: Number, required: true, min: 0, max: 5 },
});

module.exports = mongoose.model("Menu", menuSchema);
