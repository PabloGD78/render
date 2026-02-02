import 'dart:convert';

class InmuebleAnuncio {
  final String id; // ID del anuncio
  final String idUsuario; // ID del usuario propietario
  final String nombre;
  final String descripcion;
  final String precio;
  final String estado;
  final String imagenUrl; // Primera imagen
  final List<String> imagenes; // Todas las imágenes
  final List<String>? caracteristicas;

  InmuebleAnuncio({
    required this.id,
    required this.idUsuario,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.estado,
    required this.imagenUrl,
    required this.imagenes,
    this.caracteristicas,
  });

  factory InmuebleAnuncio.fromMap(Map<String, dynamic> map) {
    // Parseamos las imágenes
    List<String> listaImagenes = [];
    try {
      if (map['imagenes'] != null) {
        final dynamic parsed = map['imagenes'];
        if (parsed is String) {
          listaImagenes = List<String>.from(jsonDecode(parsed));
        } else if (parsed is List) {
          listaImagenes = List<String>.from(parsed);
        }
      }
    } catch (e) {
      listaImagenes = [];
    }

    // Parseamos características
    List<String>? listaCaracteristicas;
    try {
      if (map['caracteristicas'] != null) {
        final dynamic parsed = map['caracteristicas'];
        if (parsed is String) {
          listaCaracteristicas = List<String>.from(jsonDecode(parsed));
        } else if (parsed is List) {
          listaCaracteristicas = List<String>.from(parsed);
        }
      }
    } catch (e) {
      listaCaracteristicas = null;
    }

    return InmuebleAnuncio(
      id: map['id'].toString(), // ✅ CORREGIDO: ID del anuncio
      idUsuario: map['id_usuario'].toString(), // ✅ ID del usuario
      nombre: map['nombre'] ?? '',
      descripcion: map['desc_inmueble'] ?? '',
      precio: map['precio'] ?? '',
      estado: map['estado'] ?? 'Activo',
      imagenUrl:
          map['imagenPrincipal'] ??
          (listaImagenes.isNotEmpty ? listaImagenes[0] : ''),
      imagenes: listaImagenes,
      caracteristicas: listaCaracteristicas,
    );
  }
}
