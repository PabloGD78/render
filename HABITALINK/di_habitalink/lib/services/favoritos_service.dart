// lib/services/favorite_service.dart - CÓDIGO COMPLETO

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/property_model.dart';
import 'property_service.dart' as prop_service;

class FavoriteService {
  final String _baseUrl =
      'http://localhost:3000/api/favoritos'; // Ajusta la URL base

  // OBTENER ID DEL USUARIO (Helper)
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // ⚠️ Asegúrate de que 'user_id' se guarda al iniciar sesión.
    return prefs.getString('user_id');
  }

  // OBTENER TODOS LOS FAVORITOS DE UN USUARIO
  Future<List<PropertySummary>> getFavorites() async {
    final userId = await _getUserId();
    if (userId == null) {
      print('Error: Usuario no logeado o ID no encontrado.');
      return [];
    }

    final url = Uri.parse('$_baseUrl/user/$userId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // El backend devuelve una lista de ids de propiedad.
        final List<dynamic> data = json.decode(response.body);
        final propService = prop_service.PropertyService();
        final List<PropertySummary> results = [];
        for (final id in data) {
          try {
            final prop = await propService.obtenerPropiedadDetalle(id.toString());
            results.add(PropertySummary.fromDetailedProperty(prop));
          } catch (e) {
            // Ignorar fallos al obtener una propiedad concreta
            if (kDebugMode) print('No se pudo cargar favorito $id: $e');
          }
        }
        return results;
      } else {
        print('Error al cargar favoritos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error de conexión al obtener favoritos: $e');
      return [];
    }
  }

  // AÑADIR A FAVORITOS
  Future<bool> addFavorite(String propertyId) async {
    final userId = await _getUserId();
    if (userId == null) return false;

    final url = Uri.parse('$_baseUrl/add');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_usuario': userId, 'id_propiedad': propertyId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al añadir favorito: $e');
      return false;
    }
  }

  // ELIMINAR DE FAVORITOS
  Future<bool> removeFavorite(String propertyId) async {
    final userId = await _getUserId();
    if (userId == null) return false;

    final url = Uri.parse('$_baseUrl/remove');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_usuario': userId, 'id_propiedad': propertyId}),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error al eliminar favorito: $e');
      return false;
    }
  }
}
