import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class EditPropertyPage extends StatefulWidget {
  final Map<String, dynamic> propiedad;

  const EditPropertyPage({super.key, required this.propiedad});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // --- NUEVA PALETA DE COLORES SEGÚN TUS IMÁGENES ---
  static const Color customBackground = Color(
    0xFFF1E6CC,
  ); // El color crema de tu imagen
  static const Color customGreen = Color(
    0xFF2D5248,
  ); // El verde oscuro de tus letras
  static const Color cardColor = Color(
    0xFFF7F0E1,
  ); // Un crema ligeramente más claro para contraste

  late TextEditingController tituloController;
  late TextEditingController precioController;
  late TextEditingController descripcionController;
  late TextEditingController dormitoriosController;
  late TextEditingController banosController;
  late TextEditingController superficieController;
  late TextEditingController tipoController;
  late TextEditingController caracteristicasController;

  List<File> nuevasImagenes = [];

  @override
  void initState() {
    super.initState();
    final p = widget.propiedad;
    tituloController = TextEditingController(text: p['titulo'] ?? '');
    precioController = TextEditingController(
      text: p['precio']?.toString() ?? '',
    );
    descripcionController = TextEditingController(text: p['descripcion'] ?? '');
    dormitoriosController = TextEditingController(
      text: p['dormitorios']?.toString() ?? '',
    );
    banosController = TextEditingController(text: p['banos']?.toString() ?? '');
    superficieController = TextEditingController(
      text: p['superficie']?.toString() ?? '',
    );
    tipoController = TextEditingController(text: p['tipo'] ?? '');
    caracteristicasController = TextEditingController(
      text: (p['caracteristicas'] != null)
          ? (p['caracteristicas'] is List
                ? (p['caracteristicas'] as List).join(', ')
                : p['caracteristicas'].toString())
          : '',
    );
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked != null) {
      setState(() => nuevasImagenes.addAll(picked.map((e) => File(e.path))));
    }
  }

  Future<void> submitEdits() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final uri = Uri.parse(
      'http://localhost:3000/api/propiedades/editar/${widget.propiedad['id']}',
    );
    final request = http.MultipartRequest('PUT', uri);

    final fields = {
      'titulo': tituloController.text,
      'precio': precioController.text,
      'descripcion': descripcionController.text,
      'dormitorios': dormitoriosController.text,
      'banos': banosController.text,
      'superficie': superficieController.text,
      'tipo': tipoController.text,
      'caracteristicas': caracteristicasController.text,
    };

    fields.forEach((key, value) {
      if (value.trim().isNotEmpty) request.fields[key] = value;
    });

    for (var img in nuevasImagenes) {
      request.files.add(
        await http.MultipartFile.fromPath('imagenes', img.path),
      );
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _showSnackBar('Propiedad actualizada', customGreen);
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Error al guardar', Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar('Error de conexión', Colors.redAccent);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customBackground,
      appBar: AppBar(
        title: const Text(
          'Editar Inmueble',
          style: TextStyle(fontWeight: FontWeight.bold, color: customGreen),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: customGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: customGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('INFORMACIÓN BÁSICA'),
                    _buildCard([
                      _buildInputField(
                        'Título de la publicación',
                        tituloController,
                        Icons.edit_outlined,
                      ),
                      _buildInputField(
                        'Precio de marketo (€)',
                        precioController,
                        Icons.euro_symbol_rounded,
                        isNumber: true,
                      ),
                    ]),

                    _buildSectionHeader('ESPECIFICACIONES'),
                    _buildCard([
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              'Dormitorios',
                              dormitoriosController,
                              Icons.bed_outlined,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              'Baños',
                              banosController,
                              Icons.shower_outlined,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      _buildInputField(
                        'Área total (m²)',
                        superficieController,
                        Icons.aspect_ratio_rounded,
                        isNumber: true,
                      ),
                      _buildInputField(
                        'Tipo de propiedad',
                        tipoController,
                        Icons.home_work_outlined,
                      ),
                    ]),

                    _buildSectionHeader('DETALLES EXTRA'),
                    _buildCard([
                      _buildInputField(
                        'Características (Ej: Terraza, Aire, Garage)',
                        caracteristicasController,
                        Icons.unfold_more_rounded,
                        maxLines: 2,
                      ),
                      _buildInputField(
                        'Descripción persuasiva',
                        descripcionController,
                        Icons.description_outlined,
                        maxLines: 5,
                      ),
                    ]),

                    _buildSectionHeader('GALERÍA DE IMÁGENES'),
                    _buildImageSection(),

                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: customGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: customGreen.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style: const TextStyle(
          fontSize: 15,
          color: customGreen,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: customGreen.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, size: 20, color: customGreen),
          filled: true,
          fillColor: customBackground.withOpacity(0.3),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: customGreen.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: customGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        InkWell(
          onTap: pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: customGreen,
                width: 1.5,
                style: BorderStyle.none,
              ), // Estilo según tu imagen
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 40,
                  color: customGreen,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cargar nuevas imágenes',
                  style: TextStyle(
                    color: customGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (nuevasImagenes.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: nuevasImagenes.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: FileImage(nuevasImagenes[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: submitEdits,
        style: ElevatedButton.styleFrom(
          backgroundColor: customGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'GUARDAR CAMBIOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
