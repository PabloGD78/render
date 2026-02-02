const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    nombre: { type: String, required: true },
    apellidos: { type: String },
    tlf: { type: String },
    correo: { type: String, required: true, unique: true, lowercase: true },
    contrasenia: { type: String, required: true },
    tipo: { type: String, default: 'Particular' },
    rol: { type: String, default: 'usuario' },
    fecha_registro: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Usuario', UserSchema);