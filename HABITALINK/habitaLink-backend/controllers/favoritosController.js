const Favorito = require('../models/favoritosModel');

// OBTENER FAVORITOS DE UN USUARIO
exports.obtenerFavoritosPorUsuario = async (req, res) => {
    try {
        const { id } = req.params; // ID del Usuario
        
        // Buscamos en la tabla Favoritos donde id_usuario coincida
        const favs = await Favorito.find({ id_usuario: id }).populate('id_propiedad');

        // Filtramos por si la casa fue borrada y mapeamos
        const resultado = favs
            .filter(f => f.id_propiedad != null)
            .map(f => {
                const p = f.id_propiedad;
                return {
                    id: p._id,
                    titulo: p.titulo,
                    precio: p.precio,
                    imagenes: p.imagenes,
                    ubicacion: p.ubicacion,
                    tipo: p.tipo,
                    m2: p.m2
                };
            });

        res.status(200).json(resultado);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// AÑADIR FAVORITO
exports.anadirFavorito = async (req, res) => {
    try {
        const { id_usuario, id_propiedad } = req.body;
        
        // Upsert: crea si no existe
        await Favorito.findOneAndUpdate(
            { id_usuario, id_propiedad },
            { id_usuario, id_propiedad },
            { upsert: true, new: true }
        );

        res.status(201).json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// ELIMINAR FAVORITO
exports.eliminarFavorito = async (req, res) => {
    try {
        const { id_usuario, id_propiedad } = req.body;
        
        await Favorito.findOneAndDelete({ id_usuario, id_propiedad });
        
        res.json({ success: true, message: "Eliminado" });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};