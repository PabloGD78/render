import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  // Cambia esto por tu IP local si pruebas en móvil físico (ej: 192.168.1.XX)
  final String baseUrl = "http://localhost:3000/api/admin"; 

  // ==========================================
  //           GESTIÓN DE INMUEBLES
  // ==========================================

  // 1. Obtener lista de inmuebles
  Future<List<Map<String, dynamic>>> getProperties() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/properties'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // OJO: Asumo que tu backend devuelve { "properties": [...] }
        return List<Map<String, dynamic>>.from(data['properties']);
      }
    } catch (e) {
      print("Error en getProperties: $e");
    }
    return [];
  }

  // 2. Eliminar un inmueble (EL QUE FALTABA)
  Future<bool> deleteProperty(String id) async {
    try {
      // Llamada DELETE a /api/admin/properties/:id
      final response = await http.delete(Uri.parse('$baseUrl/properties/$id'));
      
      // Si el backend devuelve 200 OK, es que se borró
      return response.statusCode == 200;
    } catch (e) {
      print("Error en deleteProperty: $e");
      return false;
    }
  }

  // 3. Actualizar estado (Aceptar/Rechazar)
  Future<bool> updatePropertyStatus(String id, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/properties/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("Error en updatePropertyStatus: $e");
      return false;
    }
  }

  // ==========================================
  //           GESTIÓN DE USUARIOS
  // ==========================================

  /// Obtener lista de usuarios
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['users']);
      }
    } catch (e) {
      print("Error en getUsers: $e");
    }
    return [];
  }

  // Eliminar un usuario
  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("Error en deleteUser: $e");
      return false;
    }
  }
}