const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

// ==========================================
//           RUTAS DE USUARIOS
// ==========================================

// Obtener lista de todos los usuarios
router.get('/users', adminController.getUsers);

// Eliminar un usuario por ID
router.delete('/users/:id', adminController.deleteUser);


// ==========================================
//         RUTAS DE PROPIEDADES
// ==========================================

// Obtener todas las propiedades (inmueble_anuncio)
router.get('/properties', adminController.getProperties);

// Eliminar una propiedad por ID
router.delete('/properties/:id', adminController.deleteProperty);

// Actualizar el estado de una propiedad (Aprobar/Rechazar)
// Coincide con: http://localhost:3000/api/admin/properties/:id/status
router.put('/properties/:id/status', adminController.updatePropertyStatus);


// ==========================================
//           RUTAS DE DASHBOARD
// ==========================================

// Obtener datos estadísticos e informes generales
router.get('/informe', adminController.obtenerInformeGeneral);

module.exports = router;