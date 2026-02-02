const mongoose = require('mongoose');

const FavoritoSchema = new mongoose.Schema({
    id_usuario: { type: mongoose.Schema.Types.ObjectId, ref: 'Usuario', required: true },
    id_propiedad: { type: mongoose.Schema.Types.ObjectId, ref: 'Propiedad', required: true },
    fecha: { type: Date, default: Date.now }
});
// Evitar duplicados
FavoritoSchema.index({ id_usuario: 1, id_propiedad: 1 }, { unique: true });

module.exports = mongoose.model('Favorito', FavoritoSchema);