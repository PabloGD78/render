// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ⚠️ IMPORTANTE: Usamos 'localhost' para Flutter Web.
  // Si ejecutas en Android, cambia a: "http://10.0.2.2:3000/api/auth"
  final String baseUrl = "http://localhost:3000/api/auth";

  // Login
  Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasenia,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"correo": correo, "contrasenia": contrasenia}),
      );

      print("Respuesta Login: ${response.body}"); // Para depurar en consola

      // Si el backend devuelve un 500 o 401, el response.body ya contiene el JSON de error
      final data = jsonDecode(response.body);

      // Guardar sesión si login exitoso
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
  final nombre = data['user']?['nombre'] ?? '';
  final correoUsuario = data['user']?['correo'] ?? '';
  final idUsuario = data['user']?['id'] ?? '';
  final rol = data['user']?['rol'] ?? '';
  prefs.setString('user_nombre', nombre);
  prefs.setString('user_email', correoUsuario);
  prefs.setString('user_id', idUsuario);
  prefs.setString('token', data['token'] ?? '');
  prefs.setString('rol', rol); // Guardar rol para UI
  // Keys usadas en otras partes de la app
  prefs.setString('userName', nombre);
  prefs.setString('user_email', correoUsuario);
      }

      return data;
    } catch (e) {
      // Captura el error de conexión (el antiguo "Failed to fetch")
      print("Error Login: $e");
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  // Register (simplificado)
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellidos,
    required String tlf,
    required String correo,
    required String contrasenia,
  String? tipo,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/register");
      // ... resto del código ...
      final body = {
        "nombre": nombre,
        "apellidos": apellidos,
        "tlf": tlf,
        "correo": correo,
        "contrasenia": contrasenia,
      };
      if (tipo != null) body['tipo'] = tipo;

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  // Obtener usuario logeado y Logout (el resto del código es correcto)
  Future<Map<String, String>> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('user_nombre') ?? '';
    final correo = prefs.getString('user_email') ?? '';
    final token = prefs.getString('token') ?? '';
    return {"nombre": nombre, "correo": correo, "token": token};
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
