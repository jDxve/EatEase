const mongoose = require("mongoose");

const roleSchema = new mongoose.Schema({
  id: { type: Number, required: true, unique: true },
  name: { type: String, required: true },
});

roleSchema.statics.getConsumerRole = async function () {
  return await this.findOne({ id: 2 });
};

module.exports = mongoose.model("Role", roleSchema);
