import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ---------------- MODELO ----------------
class Anuncio {
  final String id;
  final String title;
  final double price;
  final int views;
  final int contacts;
  final DateTime expirationDate;
  final String imageUrl;
  final String status;
  final String tipo;

  Anuncio({
    required this.id,
    required this.title,
    required this.price,
    required this.views,
    required this.contacts,
    required this.expirationDate,
    required this.imageUrl,
    required this.status,
    required this.tipo,
  });
}

// ---------------- DASHBOARD PROFESIONAL ----------------
class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  // PALETA DE COLORES
  static const Color customBackground = Color(0xFFF1E6CC); // Crema
  static const Color customGreen = Color(0xFF2D5248); // Verde oscuro
  static const Color cardColor = Color(0xFFF7F0E1); // Crema claro

  String userName = "Cargando...";
  String? userId;
  bool isLoadingAnuncios = true;
  List<Anuncio> misAnuncios = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? finalId =
        prefs.getString('idUsuario') ??
        prefs.getString('userId') ??
        prefs.getString('id');
    String storedName = prefs.getString('userName') ?? 'Agente Inmobiliario';

    if (mounted) {
      setState(() {
        userName = storedName;
        userId = finalId;
      });
      if (finalId != null && finalId.isNotEmpty) {
        _cargarAnunciosDelBackend(finalId);
      } else {
        setState(() => isLoadingAnuncios = false);
      }
    }
  }

  Future<void> _cargarAnunciosDelBackend(String idUsuario) async {
    const String baseUrl = "http://localhost:3000";
    final url = Uri.parse('$baseUrl/api/propiedades/usuario/$idUsuario');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> listaJson = (data is Map && data.containsKey('data'))
            ? data['data']
            : (data is List ? data : []);

        List<Anuncio> tempAnuncios = listaJson.map((item) {
          return Anuncio(
            id: item['id'].toString(),
            title: item['nombre'] ?? item['titulo'] ?? 'Sin título',
            price: double.tryParse((item['precio'] ?? 0).toString()) ?? 0.0,
            views: int.tryParse((item['visitas'] ?? 0).toString()) ?? 0,
            contacts: int.tryParse((item['contactos'] ?? 0).toString()) ?? 0,
            expirationDate: DateTime.now(),
            imageUrl: 'https://via.placeholder.com/150',
            status: item['estado'] ?? 'Activo',
            tipo: item['tipo'] ?? 'Propiedad',
          );
        }).toList();

        if (mounted) {
          setState(() {
            misAnuncios = tempAnuncios;
            isLoadingAnuncios = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingAnuncios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customBackground,
      appBar: AppBar(
        title: const Text(
          'ANÁLISIS DE CARTERA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: customGreen,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: customGreen),
      ),
      // --- MENU LATERAL (DRAWER) MODIFICADO ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Cabecera profesional con estilo curvo
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: customGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: customBackground,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "P",
                      style: const TextStyle(
                        color: customGreen,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userId ?? "ID Profesional",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botón principal: Volver al Perfil
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 25),
              leading: const Icon(
                Icons.account_circle_outlined,
                color: customGreen,
              ),
              title: const Text(
                "VOLVER A MI PERFIL",
                style: TextStyle(
                  color: customGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Cierra el Drawer
                Navigator.pop(context); // Vuelve al perfil
              },
            ),
            const Divider(indent: 20, endIndent: 20),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "PANEL PROFESIONAL v1.0",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
      body: isLoadingAnuncios
          ? const Center(child: CircularProgressIndicator(color: customGreen))
          : AnalisisCarteraView(
              misAnuncios: misAnuncios,
              primaryColor: customGreen,
            ),
    );
  }
}

// ---------------- VISTA DE ANÁLISIS ----------------
class AnalisisCarteraView extends StatelessWidget {
  final List<Anuncio> misAnuncios;
  final Color primaryColor;

  final List<Color> chartColors = [
    const Color(0xFF2D5248), // Verde principal
    const Color(0xFF8B7E66), // Tierra
    const Color(0xFFC2B280), // Arena
    const Color(0xFF556B2F), // Verde oliva
    const Color(0xFFA9A9A9), // Gris
  ];

  AnalisisCarteraView({
    super.key,
    required this.misAnuncios,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (misAnuncios.isEmpty) {
      return Center(
        child: Text(
          "No hay datos para analizar",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      );
    }

    Map<String, int> conteoTipos = {};
    for (var anuncio in misAnuncios) {
      String tipoKey = anuncio.tipo.trim();
      if (tipoKey.isEmpty) tipoKey = "Otros";
      tipoKey = tipoKey[0].toUpperCase() + tipoKey.substring(1).toLowerCase();
      conteoTipos[tipoKey] = (conteoTipos[tipoKey] ?? 0) + 1;
    }

    var sortedEntries = conteoTipos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Distribución de Cartera",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 30),

          // Gráfico circular
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: PieChart(
              PieChartData(
                sections: List.generate(sortedEntries.length, (i) {
                  return PieChartSectionData(
                    color: chartColors[i % chartColors.length],
                    value: sortedEntries[i].value.toDouble(),
                    title: '${sortedEntries[i].value}',
                    radius: 60,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  );
                }),
                centerSpaceRadius: 45,
                sectionsSpace: 4,
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Leyenda
          Center(
            child: Wrap(
              spacing: 15,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(sortedEntries.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: chartColors[i % chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sortedEntries[i].key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 40),

          // Tarjeta de resumen
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0E1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSimpleRow(
                  "Total Propiedades",
                  "${misAnuncios.length}",
                  primaryColor,
                  isBold: true,
                ),
                const Divider(height: 30, thickness: 1),
                ...sortedEntries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildSimpleRow(e.key, "${e.value}", Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
