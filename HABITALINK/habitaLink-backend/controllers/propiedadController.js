const Propiedad = require('../models/propiedadModel');
const fs = require('fs');
const path = require('path');

// 1. CREAR PROPIEDAD
exports.crearPropiedad = async (req, res) => {
    try {
        const imagenesUrls = req.files ? req.files.map(f => `/uploads/${f.filename}`) : [];
        let caracs = [];
        if (req.body.caracteristicas) {
            try { caracs = JSON.parse(req.body.caracteristicas); } 
            catch (e) { caracs = [req.body.caracteristicas]; }
        }

        const nueva = new Propiedad({
            id_usuario: req.body.id_usuario,
            titulo: req.body.titulo,
            
            // Aceptamos que el frontend nos mande cualquiera de los dos nombres
            desc_inmueble: req.body.desc_inmueble || req.body.descripcion, 
            
            precio: Number(req.body.precio),
            num_habitaciones: Number(req.body.dormitorios || 0),
            num_baños: Number(req.body.banos || 0),
            m2: Number(req.body.superficie || 0),
            tipo: req.body.tipo,
            ubicacion: req.body.ubicacion,
            latitude: Number(req.body.latitude || 0),
            longitude: Number(req.body.longitude || 0),
            caracteristicas: caracs,
            imagenes: imagenesUrls
        });

        const guardada = await nueva.save();
        res.status(201).json({ success: true, message: 'Creada', propiedadId: guardada._id });
    } catch (error) {
        console.error("Error al crear:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};
// 2. OBTENER TODAS (Con corrección de IMÁGENES)
exports.obtenerPropiedades = async (req, res) => {
    try {
        const props = await Propiedad.find().sort({ fecha_creacion: -1 });
        
        // CAMBIA ESTO SI USAS EMULADOR ANDROID:
        // Si usas Web: 'http://localhost:3000'
        // Si usas Emulador Android: 'http://10.0.2.2:3000'
        const baseUrl = 'http://192.168.1.1:3000';

        const resultado = props.map(p => {
            // Procesamos las imagenes para que lleven la url completa
            const imagenesCompletas = p.imagenes.map(img => {
                // Si ya tiene http (por si acaso), lo dejamos, si no, se lo ponemos
                return img.startsWith('http') ? img : `${baseUrl}${img}`;
            });

            return {
                ...p._doc,
                id: p._id,
                
                // Traducción de textos y números
                descripcion: p.desc_inmueble,
                desc_inmueble: p.desc_inmueble,
                dormitorios: p.num_habitaciones,
                num_habitaciones: p.num_habitaciones,
                banos: p.num_baños,
                num_baños: p.num_baños,
                superficie: p.m2,
                m2: p.m2,
                
                // ⚠️ AQUÍ ENVIAMOS LAS FOTOS ARREGLADAS
                imagenes: imagenesCompletas, 
                // Y enviamos la primera como portada
                imagenPrincipal: imagenesCompletas.length > 0 ? imagenesCompletas[0] : null
            };
        });

        res.json({ success: true, propiedades: resultado });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 3. MIS ANUNCIOS
exports.obtenerMisAnuncios = async (req, res) => {
    try {
        const props = await Propiedad.find({ id_usuario: req.params.id_usuario }).sort({ fecha_creacion: -1 });
        const dataProcesada = props.map(p => ({ 
            ...p._doc, 
            id: p._id, 
            imagenPrincipal: (p.imagenes && p.imagenes.length > 0) ? p.imagenes[0] : '',
            // Traducción también aquí
            descripcion: p.desc_inmueble 
        }));
        res.json({ success: true, data: dataProcesada });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error al cargar anuncios" });
    }
};
// 4. DETALLE POR ID (Mejorado para enviar nombres compatibles)
exports.obtenerPropiedadDetalle = async (req, res) => {
    try {
        const p = await Propiedad.findById(req.params.id).populate('id_usuario', 'nombre tlf correo');
        
        if (!p) return res.status(404).json({ success: false, message: "No encontrada" });
        
        // Preparamos el objeto "traduciendo" los campos numéricos
        const propiedadProcesada = {
            ...p._doc,
            id: p._id,
            
            // TRADUCCIÓN DE TEXTOS
            descripcion: p.desc_inmueble, 
            
            // TRADUCCIÓN DE NÚMEROS (Enviamos AMBOS nombres)
            // Para habitaciones
            num_habitaciones: p.num_habitaciones,
            dormitorios: p.num_habitaciones, // La App suele buscar esto
            
            // Para baños
            num_baños: p.num_baños,
            banos: p.num_baños, // La App suele buscar esto
            
            // Para superficie
            m2: p.m2,
            superficie: p.m2 // La App suele buscar esto
        };

        res.json({ success: true, propiedad: propiedadProcesada });

    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
// 5. EDITAR PROPIEDAD (Versión Robusta)
exports.editarPropiedad = async (req, res) => {
    try {
        const updates = { ...req.body };

        // Función auxiliar para limpiar números (quita letras y símbolos como € o m2)
        const limpiarNumero = (valor) => {
            if (!valor) return 0;
            return parseFloat(valor.toString().replace(/[^\d.]/g, '')) || 0;
        };

        // --- 1. PROCESAR PRECIO ---
        if (updates.precio) {
            updates.precio = limpiarNumero(updates.precio);
        }

        // --- 2. PROCESAR SUPERFICIE (m2 vs superficie) ---
        // Si me llega 'superficie', lo guardo en 'm2'
        if (updates.superficie !== undefined) {
            updates.m2 = limpiarNumero(updates.superficie);
        } else if (updates.m2 !== undefined) {
             // Si por casualidad llega ya como m2, también lo limpiamos
            updates.m2 = limpiarNumero(updates.m2);
        }

        // --- 3. PROCESAR HABITACIONES (num_habitaciones vs dormitorios) ---
        if (updates.dormitorios !== undefined) {
            updates.num_habitaciones = limpiarNumero(updates.dormitorios);
        } else if (updates.num_habitaciones !== undefined) {
            updates.num_habitaciones = limpiarNumero(updates.num_habitaciones);
        }

        // --- 4. PROCESAR BAÑOS (num_baños vs banos) ---
        if (updates.banos !== undefined) {
            updates.num_baños = limpiarNumero(updates.banos);
        } else if (updates.num_baños !== undefined) {
            updates.num_baños = limpiarNumero(updates.num_baños);
        }

        // --- 5. DESCRIPCIÓN ---
        if (updates.descripcion && !updates.desc_inmueble) {
            updates.desc_inmueble = updates.descripcion;
        }

        // --- 6. IMÁGENES ---
        if (req.files && req.files.length > 0) {
            updates.imagenes = req.files.map(f => `/uploads/${f.filename}`);
        }
        
        const propiedad = await Propiedad.findByIdAndUpdate(req.params.id, updates, { new: true });

        if (!propiedad) return res.status(404).json({ success: false, message: "Propiedad no encontrada" });

        res.json({ success: true, message: 'Propiedad actualizada', propiedad });
    } catch (error) {
        console.error("Error al editar:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};
// 6. ELIMINAR PROPIEDAD
exports.eliminarPropiedad = async (req, res) => {
    try {
        await Propiedad.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: 'Propiedad eliminada' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};