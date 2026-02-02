class UserModel {
  final String nombre;
  final String email;
  final String token;
  final String rol; // ✅ Añadido campo rol

  UserModel({
    required this.nombre, 
    required this.email, 
    required this.token,
    required this.rol, // ✅ Añadido al constructor
  });

  // Constructor factory actualizado
  factory UserModel.fromMap(Map<String, String> data) {
    return UserModel(
      nombre: data['nombre'] ?? '',
      email: data['correo'] ?? '',
      token: data['token'] ?? '',
      rol: data['rol'] ?? 'usuario', // ✅ Captura el rol (por defecto 'usuario')
    );
  }
}