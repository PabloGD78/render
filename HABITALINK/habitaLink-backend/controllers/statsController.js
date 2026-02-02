const Usuario = require('../models/userModel');
const Propiedad = require('../models/propiedadModel');

// ESTADÍSTICAS ADMIN (Igual que en adminController)
exports.getEstadisticasAdmin = async (req, res) => {
    try {
        const totalUsuarios = await Usuario.countDocuments();
        const totalPropiedades = await Propiedad.countDocuments();
        
        const distribucion = await Usuario.aggregate([
            { $group: { _id: "$tipo", cantidad: { $sum: 1 } } }
        ]);

        res.json({
            success: true,
            totalUsuarios,
            totalPropiedades,
            distribucionUsuarios: distribucion.map(d => ({ rol: d._id || 'Sin definir', cantidad: d.cantidad }))
        });

    } catch (error) {
        res.status(500).json({ success: false, message: "Error stats" });
    }
};

// ESTADÍSTICAS AGENCIA
exports.getEstadisticasAgencia = async (req, res) => {
    // Para tener gráficas de visitas en Mongo, necesitarías crear una colección nueva 'Visitas'.
    // Devolvemos array vacío para que la App no falle.
    res.json({
        success: true,
        data: [] 
    });
};