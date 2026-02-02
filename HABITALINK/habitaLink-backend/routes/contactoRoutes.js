const express = require('express');
const router = express.Router();
const contactoController = require('../controllers/contactoController');

router.post('/', contactoController.enviarMensaje);
router.get('/', contactoController.obtenerMensajes); // Solo admin debería ver esto

module.exports = router;