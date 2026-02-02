import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:di_habitalink/theme/colors.dart';

// ➕ Librerías para mapa
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// -----------------------------------------------------------
// SERVICIO API INTEGRADO (ListingService)
// -----------------------------------------------------------
class ListingService {
  static const String apiUrl = 'http://localhost:3000/api/propiedades/crear';

  static Future<bool> subirAnuncio({
    required String titulo,
    required String precio,
    required String descripcion,
    required String dormitorios,
    required String banos,
    required String superficie,
    required String tipo,
    String? ubicacion,
    List<String>? caracteristicas,
    List<Map<String, dynamic>>? images,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print("Error: Usuario no logeado.");
        return false;
      }

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.fields['id_usuario'] = userId;
      request.fields['titulo'] = titulo;
      request.fields['precio'] = precio;
      request.fields['descripcion'] = descripcion;
      request.fields['descripcion_larga'] = descripcion;
      request.fields['dormitorios'] = dormitorios;
      request.fields['banos'] = banos;
      request.fields['superficie'] = superficie;
      request.fields['tipo'] = tipo;
      if (ubicacion != null) request.fields['ubicacion'] = ubicacion;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      if (caracteristicas != null) {
        final String featuresJson = (caracteristicas is String)
            ? (caracteristicas as String)
            : jsonEncode(caracteristicas);
        request.fields['caracteristicas'] = featuresJson;
      }

      if (images != null && images.isNotEmpty) {
        for (var img in images) {
          if (img['path'] != null && !kIsWeb) {
            request.files.add(
              await http.MultipartFile.fromPath('imagenes', img['path']),
            );
          } else if (img['bytes'] != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'imagenes',
                img['bytes'],
                filename: img['name'] ?? 'imagen.jpg',
              ),
            );
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Error del servidor (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de conexión: $e");
      return false;
    }
  }
}

// -----------------------------------------------------------
// PÁGINA DEL FORMULARIO (NewPropertyCardPage)
// -----------------------------------------------------------
class NewPropertyCardPage extends StatefulWidget {
  const NewPropertyCardPage({super.key});

  @override
  State<NewPropertyCardPage> createState() => _NewPropertyCardPageState();
}

class _NewPropertyCardPageState extends State<NewPropertyCardPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dormitoriosCtrl = TextEditingController();
  final _banosCtrl = TextEditingController();
  final _superficieCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();

  final Map<String, bool> _features = {
    'Piscina': false,
    'Jardín': false,
    'Patio': false,
    'Terraza': false,
  };

  List<Map<String, dynamic>> _images = [];
  bool _isUploading = false;

  // ➕ Ubicación y controlador de mapa
  LatLng? coords;
  final MapController mapController = MapController();

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _precioCtrl.dispose();
    _descCtrl.dispose();
    _dormitoriosCtrl.dispose();
    _banosCtrl.dispose();
    _superficieCtrl.dispose();
    _tipoCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _images = result.files
            .map(
              (file) => {
                "path": kIsWeb ? null : file.path,
                "bytes": file.bytes,
                "name": file.name,
              },
            )
            .toList();
      });
    }
  }

  // ➕ Buscar coordenadas (Lógica mejorada)
  // ✅ Esta función usa Nominatim para convertir la ubicación de texto en coordenadas exactas (latitude, longitude)
  // Estas coordenadas serán guardadas en la BD y mostradas en el mapa del detalle
  Future<void> buscarUbicacion() async {
    if (_ubicacionCtrl.text.isEmpty) return;

    try {
      // Añadimos ", España" para asegurar que encuentre el resultado
      final String busquedaCompleta = "${_ubicacionCtrl.text}, España";
      final query = Uri.encodeComponent(busquedaCompleta);

      // Usamos una URL de búsqueda más permisiva
      final url =
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'HabitaLink_App_v1', // Identificador necesario para el servicio
          'Accept-Language': 'es',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);

          setState(() {
            coords = LatLng(lat, lon);
          });

          // ✅ Mover el mapa suavemente al punto encontrado (estas son las coordenadas exactas que se guardarán)
          mapController.move(coords!, 15);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ubicación encontrada: ${data[0]['display_name'] ?? 'Localizado'}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Si no encuentra nada, avisar al usuario
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ubicación no encontrada. Intenta ser más específico.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      print("Error en geocoding: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar al menos una foto'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ✅ VERIFICACIÓN: Si hay ubicación en el formulario, debe estar búsqueda (coords debe ser != null)
      if (_ubicacionCtrl.text.isNotEmpty && coords == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, busca la ubicación haciendo clic en la lupa 🔍',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() => _isUploading = true);

      final selectedFeatures = _features.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // ✅ GUARDAR: Las coordenadas exactas que se buscaron (latitude, longitude)
      bool exito = await ListingService.subirAnuncio(
        titulo: _tituloCtrl.text,
        precio: _precioCtrl.text,
        descripcion: _descCtrl.text,
        dormitorios: _dormitoriosCtrl.text,
        banos: _banosCtrl.text,
        superficie: _superficieCtrl.text,
        tipo: _tipoCtrl.text,
        ubicacion: _ubicacionCtrl.text,
        caracteristicas: selectedFeatures,
        images: _images,
        latitude: coords?.latitude, // ✅ Coordenadas exactas del formulario
        longitude: coords?.longitude,
      );

      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exito
                  ? '¡Anuncio publicado con éxito! Ubicación exacta guardada 📍'
                  : 'Error al publicar anuncio.',
            ),
            backgroundColor: exito ? Colors.green : Colors.red,
          ),
        );
        if (exito) Navigator.pop(context);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.hintTextColor),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildFeaturesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            'Características',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: _features.keys.map((k) {
            return FilterChip(
              label: Text(k),
              selected: _features[k]!,
              onSelected: (val) => setState(() => _features[k] = val),
            );
          }).toList(),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Crear Nuevo Anuncio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isUploading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SizedBox(
                  width: 800,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          label: 'Título',
                          controller: _tituloCtrl,
                        ),
                        _buildTextField(
                          label: 'Precio (€)',
                          controller: _precioCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          label: 'Descripción',
                          controller: _descCtrl,
                          maxLines: 3,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Dormitorios',
                                controller: _dormitoriosCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                label: 'Baños',
                                controller: _banosCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Superficie (m²)',
                                controller: _superficieCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                label: 'Tipo',
                                controller: _tipoCtrl,
                                hint: 'Piso, Chalet...',
                              ),
                            ),
                          ],
                        ),
                        _buildTextField(
                          label: 'Ubicación',
                          controller: _ubicacionCtrl,
                          hint: 'Ej: Plaza de la Encarnación, Sevilla',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: Colors.blue),
                            onPressed: buscarUbicacion,
                          ),
                        ),

                        // ➕ MAPA VISUAL CON UBICACIÓN EXACTA
                        if (coords != null)
                          Container(
                            height: 250,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: mapController,
                                    // ✅ Mostrar exactamente la ubicación encontrada (estas coordenadas se guardarán)
                                    options: MapOptions(
                                      center: coords!,
                                      zoom: 15,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                        userAgentPackageName:
                                            'com.habitalink.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            // ✅ Marcador exacto en las coordenadas de búsqueda
                                            point: coords!,
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // ✅ Indicador visual de precisión
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Lat: ${coords!.latitude.toStringAsFixed(6)}, Lon: ${coords!.longitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        _buildFeaturesSelector(),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _images.isEmpty
                                ? "Seleccionar Fotos"
                                : "${_images.length} fotos seleccionadas",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.hintTextColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'PUBLICAR ANUNCIO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
