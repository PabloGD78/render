import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/property_model.dart';

const baseUrl = 'http://192.168.1.1:3000';
const String API_URL = '$baseUrl/api/propiedades';

class PropertyService {
  // ---------------------------------------------------------------------------
  // 1. OBTENER DETALLE DE UNA SOLA PROPIEDAD
  // ---------------------------------------------------------------------------
  Future<Property> obtenerPropiedadDetalle(String propertyId) async {
    final url = Uri.parse('$API_URL/$propertyId');

    if (kDebugMode) {
      print('🚀 Solicitando detalle de propiedad en: $url');
    }

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true &&
            jsonResponse.containsKey('propiedad')) {
          final Map<String, dynamic> propertyJson = jsonResponse['propiedad'];
          return Property.fromJson(propertyJson);
        } else {
          throw Exception(
            'Error: Respuesta exitosa pero formato de datos inesperado.',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception(
          'Error 404: Propiedad no encontrada con ID: $propertyId.',
        );
      } else {
        throw Exception(
          'Error al cargar detalle de propiedad. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en obtenerPropiedadDetalle: $e');
      }
      throw Exception(
        'Fallo al obtener detalle de propiedad. Revise la conexión. Detalles: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 2. OBTENER TODAS LAS PROPIEDADES
  // ---------------------------------------------------------------------------
  Future<List<PropertySummary>> obtenerTodas() async {
    final url = Uri.parse(API_URL);

    if (kDebugMode) {
      print('🚀 Solicitando lista de propiedades en: $url');
    }

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true &&
            jsonResponse.containsKey('propiedades')) {
          final List<dynamic> propertiesList = jsonResponse['propiedades'];
          return propertiesList
              .map((jsonItem) => PropertySummary.fromJson(jsonItem))
              .toList();
        } else {
          throw Exception(
            'Error: Respuesta exitosa pero lista de propiedades no encontrada.',
          );
        }
      } else {
        throw Exception(
          'Error al cargar propiedades. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en obtenerTodas: $e');
      }
      throw Exception(
        'Fallo al obtener la lista de propiedades. Revise la conexión. Detalles: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3. OBTENER PROPIEDADES POR TIPO (para similares)
  // ---------------------------------------------------------------------------
  Future<List<PropertySummary>> obtenerPropiedadesPorTipo(String tipo) async {
    try {
      // Primero obtenemos todas las propiedades
      final allProperties = await obtenerTodas();

      // Filtramos por tipo
      final filtered = allProperties.where((prop) {
        return prop.type.toLowerCase() == tipo.toLowerCase();
      }).toList();

      return filtered;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en obtenerPropiedadesPorTipo: $e');
      }
      throw Exception('Fallo al obtener propiedades por tipo. Detalles: $e');
    }
  }
}
