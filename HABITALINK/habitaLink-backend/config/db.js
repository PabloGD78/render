const mongoose = require('mongoose');
require('dotenv').config(); // Esto lee el archivo .env

const connectDB = async () => {
    try {
        // Mongoose 9+ (tu versión) ya no necesita opciones extra
        const conn = await mongoose.connect(process.env.MONGO_URI);

        console.log(`✅ MongoDB Conectado: ${conn.connection.host}`);
    } catch (error) {
        console.error(`❌ Error: ${error.message}`);
        
        // Si falla, te dará una pista clara
        if(error.message.includes('bad auth')) {
            console.log('💡 Pista: Revisa tu usuario y contraseña en el archivo .env');
        }
        
        process.exit(1);
    }
};

module.exports = connectDB;