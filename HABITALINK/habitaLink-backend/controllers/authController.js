const Usuario = require('../models/userModel');
const bcrypt = require('bcrypt');

exports.login = async (req, res) => {
    try {
        // Normalizamos correo a minúsculas
        const correo = req.body.correo ? req.body.correo.toLowerCase() : "";
        const { contrasenia } = req.body;

        // 1. Buscar usuario (Mongoose)
        const user = await Usuario.findOne({ correo });

        if (!user) {
            return res.status(401).json({ success: false, message: "Correo o contraseña incorrectos." });
        }

        // 2. Verificar contraseña
        const passwordMatch = await bcrypt.compare(contrasenia, user.contrasenia);
        
        if (!passwordMatch) {
            return res.status(401).json({ success: false, message: "Correo o contraseña incorrectos." });
        }

        // 3. Responder (Mapeamos _id a id)
        res.json({
            success: true,
            message: "Login exitoso",
            user: {
                id: user._id,
                nombre: user.nombre,
                email: user.correo,
                rol: user.rol,
                tipo: user.tipo
            }
        });

    } catch (error) {
        console.error("Error Login:", error);
        res.status(500).json({ success: false, message: "Error en el servidor" });
    }
};

exports.register = async (req, res) => {
    try {
        const { nombre, apellidos, tlf, contrasenia, tipo } = req.body;
        const correo = req.body.correo ? req.body.correo.toLowerCase() : "";

        // 1. Verificar si existe
        const existe = await Usuario.findOne({ correo });
        if (existe) {
            return res.status(409).json({ success: false, message: "El correo ya está registrado." });
        }

        // 2. Encriptar contraseña
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash(contrasenia, salt);

        // 3. Crear usuario
        const nuevoUsuario = new Usuario({
            nombre,
            apellidos,
            tlf,
            correo,
            contrasenia: hash, // Guardamos el hash
            tipo: tipo || 'Particular',
            rol: 'usuario'
        });

        await nuevoUsuario.save();

        res.status(201).json({
            success: true,
            message: "Usuario registrado correctamente.",
            tipo: nuevoUsuario.tipo
        });

    } catch (error) {
        console.error("Error Registro:", error);
        res.status(500).json({ success: false, message: "Error al registrar usuario." });
    }
};