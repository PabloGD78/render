const express = require('express');
const cors = require('cors');
const path = require('path'); // Importante para las rutas de archivos
const fs = require('fs');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();

// ==========================================
// 1. CONEXIÓN A BASE DE DATOS (MONGODB)
// ==========================================
mongoose.connect(process.env.MONGO_URI)
    .then(() => console.log('✅ MongoDB Conectado correctamente'))
    .catch(err => {
        console.error('❌ Error al conectar a MongoDB:', err);
        process.exit(1);
    });

// ==========================================
// 2. MIDDLEWARES
// ==========================================
app.use(cors()); // Permite conexiones desde cualquier sitio
app.use(express.json()); // Permite leer JSON

// ==========================================
// 3. CARPETA DE IMÁGENES PÚBLICA (CRUCIAL PARA TUS FOTOS)
// ==========================================
// Define la ruta física de la carpeta
const uploadsDir = path.join(__dirname, 'uploads');

// Si la carpeta no existe, la crea (para evitar errores)
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir);
    console.log('📂 Carpeta uploads creada automáticamente');
}

// ESTA ES LA LÍNEA MÁGICA:
// Dice: "Cuando alguien pida algo que empiece por /uploads, busca el archivo en la carpeta física"
app.use('/uploads', express.static(uploadsDir));


// ==========================================
// 4. RUTAS
// ==========================================
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/propiedades', require('./routes/propiedadRoutes'));
// app.use('/api/favoritos', require('./routes/favoritosRoutes')); // Descomenta si lo tienes
// app.use('/api/admin', require('./routes/adminRoutes'));         // Descomenta si lo tienes
// app.use('/api/stats', require('./routes/statsRoutes'));         // Descomenta si lo tienes
// app.use('/api/visitas', require('./routes/visitaRoutes'));      // Descomenta si lo tienes
// app.use('/api/contacto', require('./routes/contactoRoutes'));   // Descomenta si lo tienes

// Ruta de prueba para ver si el servidor respira
app.get('/', (req, res) => {
    res.send('API HabitaLink funcionando 🚀');
});

// ==========================================
// 5. ARRANCAR SERVIDOR
// ==========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});