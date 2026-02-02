const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statsController');

// Ruta: /api/stats/admin
// Esta es la que llama tu Dashboard en Flutter
router.get('/admin', statsController.getEstadisticasAdmin);

// Ruta: /api/stats/agencia/:id_usuario
router.get('/agencia/:id_usuario', statsController.getEstadisticasAgencia);

module.exports = router;