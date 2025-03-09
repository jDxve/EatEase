const mongoose = require("mongoose");

const categorySchema = new mongoose.Schema({
  _id: { type: mongoose.Schema.Types.ObjectId, auto: true },
  id: { type: Number, required: true, unique: true },
  name: { type: String, required: true },
});

module.exports = mongoose.model("Category", categorySchema);
