const express = require('express');
const router = express.Router();
const favoritosController = require('../controllers/favoritosController');

// Obtener favoritos de un usuario
router.get('/user/:id', favoritosController.obtenerFavoritosPorUsuario);

// Añadir favorito
router.post('/add', favoritosController.anadirFavorito);

// Eliminar favorito
router.delete('/remove', favoritosController.eliminarFavorito);

module.exports = router;
