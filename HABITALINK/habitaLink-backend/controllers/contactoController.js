const Contacto = require('../models/contactoModel');

exports.enviarMensaje = async (req, res) => {
    try {
        const nuevoMensaje = new Contacto(req.body);
        await nuevoMensaje.save();
        res.status(201).json({ success: true, message: "Mensaje enviado correctamente" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error al enviar mensaje" });
    }
};

exports.obtenerMensajes = async (req, res) => { // Para el Admin
    try {
        const mensajes = await Contacto.find().sort({ fecha: -1 });
        res.json({ success: true, data: mensajes });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};