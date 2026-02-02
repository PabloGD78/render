const mongoose = require('mongoose');

const ContactoSchema = new mongoose.Schema({
    nombre: { type: String, required: true },
    email: { type: String, required: true },
    asunto: { type: String },
    mensaje: { type: String, required: true },
    fecha: { type: Date, default: Date.now },
    leido: { type: Boolean, default: false } // Para que el admin sepa si lo vio
});

module.exports = mongoose.model('Contacto', ContactoSchema);