const mongoose = require('mongoose');

const PropiedadSchema = new mongoose.Schema({
    id_usuario: { type: mongoose.Schema.Types.ObjectId, ref: 'Usuario', required: true },
    titulo: { type: String, required: true },
    
    // ✅ VOLVEMOS A TU NOMBRE ORIGINAL
    desc_inmueble: { type: String, required: true }, 

    precio: { type: Number, required: true },
    num_habitaciones: { type: Number, default: 0 },
    num_baños: { type: Number, default: 0 },
    m2: { type: Number, default: 0 },
    tipo: { 
        type: String, 
        enum: ['Casa', 'Piso', 'Chalet', 'Atico', 'Duplex', 'Loft', 'Apartamento'],
        required: true 
    },
    estado: { 
        type: String, 
        enum: ['en venta', 'alquiler', 'reservado', 'vendido'], 
        default: 'en venta' 
    },
    ubicacion: { type: String, required: true },
    latitude: { type: Number, default: 0 },
    longitude: { type: Number, default: 0 },
    caracteristicas: [String],
    imagenes: [String],
    fecha_creacion: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Propiedad', PropiedadSchema);