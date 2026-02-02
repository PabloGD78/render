const Visita = require('../models/visitaModel');
const Propiedad = require('../models/propiedadModel');

// 1. SOLICITAR VISITA
exports.solicitarVisita = async (req, res) => {
    try {
        const { id_usuario, id_propiedad, fecha, mensaje } = req.body;
        
        const nuevaVisita = new Visita({
            id_usuario,
            id_propiedad,
            fecha_solicitada: new Date(fecha),
            mensaje
        });

        await nuevaVisita.save();
        res.status(201).json({ success: true, message: "Solicitud de visita enviada" });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 2. VER MIS VISITAS (Como Usuario o como Propietario)
exports.obtenerMisVisitas = async (req, res) => {
    try {
        const { id_usuario } = req.params;
        
        // Buscamos visitas donde el usuario es el que visita O el dueño de la casa
        // (Esta lógica se puede refinar, aquí traigo las que el usuario pidió)
        const visitas = await Visita.find({ id_usuario })
            .populate('id_propiedad', 'titulo precio ubicacion imagenes')
            .sort({ fecha_solicitada: 1 });

        res.json({ success: true, data: visitas });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error al obtener visitas" });
    }
};

// 3. CAMBIAR ESTADO (Aceptar/Rechazar)
exports.cambiarEstadoVisita = async (req, res) => {
    try {
        const { estado } = req.body; // 'aceptada' o 'rechazada'
        await Visita.findByIdAndUpdate(req.params.id, { estado });
        res.json({ success: true, message: `Visita ${estado}` });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};