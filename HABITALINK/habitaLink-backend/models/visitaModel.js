const mongoose = require('mongoose');

const VisitaSchema = new mongoose.Schema({
    id_usuario: { type: mongoose.Schema.Types.ObjectId, ref: 'Usuario', required: true }, // Quien pide la cita
    id_propiedad: { type: mongoose.Schema.Types.ObjectId, ref: 'Propiedad', required: true }, // Qué piso quiere ver
    fecha_solicitada: { type: Date, required: true },
    mensaje: { type: String }, // Comentario del usuario
    estado: { 
        type: String, 
        enum: ['pendiente', 'aceptada', 'rechazada', 'realizada'], 
        default: 'pendiente' 
    },
    fecha_creacion: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Visita', VisitaSchema);