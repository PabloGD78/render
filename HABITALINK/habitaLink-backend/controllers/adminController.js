const Usuario = require('../models/userModel');
const Propiedad = require('../models/propiedadModel');

// GET USERS
exports.getUsers = async (req, res) => {
    try {
        const users = await Usuario.find();
        const usersMapped = users.map(u => ({
            id: u._id,
            nombre: u.nombre,
            apellidos: u.apellidos,
            correo: u.correo,
            tlf: u.tlf,
            tipo: u.tipo,
            rol: u.rol
        }));
        res.json({ success: true, users: usersMapped });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error al obtener usuarios" });
    }
};

// DELETE USER
exports.deleteUser = async (req, res) => {
    try {
        await Usuario.findByIdAndDelete(req.params.id);
        // Opcional: Propiedad.deleteMany({ id_usuario: req.params.id });
        res.json({ success: true, message: "Usuario eliminado" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error eliminando usuario" });
    }
};

// GET PROPERTIES
exports.getProperties = async (req, res) => {
    try {
        const propiedades = await Propiedad.find().populate('id_usuario', 'correo');
        const resultado = propiedades.map(p => ({
            id: p._id,
            nombre: p.titulo, // Admin panel espera 'nombre'
            precio: p.precio,
            tipo: p.tipo,
            estado: p.estado || 'pendiente',
            ubicacion: p.ubicacion,
            propietario: p.id_usuario ? p.id_usuario.correo : 'Eliminado'
        }));
        res.json({ success: true, properties: resultado });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error obteniendo propiedades" });
    }
};

// DELETE PROPERTY
exports.deleteProperty = async (req, res) => {
    try {
        await Propiedad.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: "Propiedad eliminada" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error eliminando propiedad" });
    }
};

// UPDATE STATUS
exports.updatePropertyStatus = async (req, res) => {
    try {
        await Propiedad.findByIdAndUpdate(req.params.id, { estado: req.body.status });
        res.json({ success: true, message: "Estado actualizado" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error actualizando estado" });
    }
};

// DASHBOARD
exports.obtenerInformeGeneral = async (req, res) => {
    try {
        const [usuariosTipo, anunciosTipo, totalUsers, totalProps] = await Promise.all([
            Usuario.aggregate([{ $group: { _id: "$tipo", cantidad: { $sum: 1 } } }]),
            Propiedad.aggregate([{ $group: { _id: "$tipo", cantidad: { $sum: 1 } } }]),
            Usuario.countDocuments(),
            Propiedad.countDocuments()
        ]);

        res.json({
            success: true,
            data: {
                usuariosTipo: usuariosTipo.map(u => ({ tipo: u._id || 'Otro', cantidad: u.cantidad })),
                anunciosPorTipo: anunciosTipo.map(a => ({ tipo: a._id || 'Otro', cantidad: a.cantidad })),
                usuariosActivos: totalUsers, // Dato simplificado
                totalAnuncios: totalProps
            }
        });
    } catch (error) {
        console.error("Error Dashboard:", error);
        res.status(500).json({ success: false, message: "Error generando informe" });
    }
};