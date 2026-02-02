const express = require('express');
const router = express.Router();
const propiedadController = require('../controllers/propiedadController');
const multer = require('multer');
const path = require('path');

// Configuración de Multer (Igual que antes)
const storage = multer.diskStorage({
    destination: function (req, file, cb) { cb(null, 'uploads/'); },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// RUTAS

// 1. Crear
router.post('/crear', upload.array('imagenes', 5), propiedadController.crearPropiedad);

// 2. Obtener todas
router.get('/', propiedadController.obtenerPropiedades);

// 3. OBTENER MIS ANUNCIOS (¡AQUÍ ESTABA EL FALLO!)
// Antes ponía '/mis-anuncios/:id_usuario', ahora ponemos lo que busca tu Flutter:
router.get('/usuario/:id_usuario', propiedadController.obtenerMisAnuncios); 

// 4. Detalle
router.get('/:id', propiedadController.obtenerPropiedadDetalle);

// 5. Editar
router.put('/editar/:id', upload.array('imagenes', 5), propiedadController.editarPropiedad);

// 6. Eliminar
router.delete('/:id', propiedadController.eliminarPropiedad);

module.exports = router;