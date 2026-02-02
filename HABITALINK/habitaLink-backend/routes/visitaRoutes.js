const express = require('express');
const router = express.Router();
const visitaController = require('../controllers/visitaController');

router.post('/solicitar', visitaController.solicitarVisita);
router.get('/usuario/:id_usuario', visitaController.obtenerMisVisitas);
router.put('/:id/estado', visitaController.cambiarEstadoVisita);

module.exports = router;