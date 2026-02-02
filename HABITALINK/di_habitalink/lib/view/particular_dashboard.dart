import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../theme/colors.dart';

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

// ---------------- DASHBOARD ÚNICO (MÉTRICAS) ----------------
class ParticularDashboard extends StatefulWidget {
  const ParticularDashboard({super.key});

  @override
  State<ParticularDashboard> createState() => _ParticularDashboardState();
}

class _ParticularDashboardState extends State<ParticularDashboard> {
  final Color _primaryColor = AppColors.primary;
  final Color _backgroundColor = const Color(0xFFF3E5CD);

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
    String storedName = prefs.getString('userName') ?? 'Usuario';

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
            tipo: item['tipo'] ?? 'Desconocido',
          );
        }).toList();

        if (mounted)
          setState(() {
            misAnuncios = tempAnuncios;
            isLoadingAnuncios = false;
          });
      } else {
        if (mounted) setState(() => isLoadingAnuncios = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingAnuncios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ANÁLISIS DE CARTERA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_open_rounded, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => isLoadingAnuncios = true);
              _loadUserData();
            },
          ),
        ],
      ),
      // --- MENU LATERAL PROFESIONAL ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      userName[0].toUpperCase(),
                      style: TextStyle(
                        color: _primaryColor,
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
                    userId ?? "ID Usuario",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // OPCIÓN VOLVER AL PERFIL (Estilo Profesional)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 25),
              leading: Icon(
                Icons.account_circle_outlined,
                color: _primaryColor,
              ),
              title: const Text(
                "VOLVER A MI PERFIL",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Cierra drawer
                Navigator.pop(context); // Vuelve al perfil
              },
            ),
            const Divider(indent: 20, endIndent: 20),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "GESTIÓN PROFESIONAL",
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
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : EstadisticasView(
              misAnuncios: misAnuncios,
              primaryColor: _primaryColor,
            ),
    );
  }
}

// ---------------- VISTA DE ESTADÍSTICAS PROFESIONAL ----------------
class EstadisticasView extends StatelessWidget {
  final List<Anuncio> misAnuncios;
  final Color primaryColor;
  const EstadisticasView({
    super.key,
    required this.misAnuncios,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (misAnuncios.isEmpty) {
      return const Center(
        child: Text(
          "No hay datos para mostrar gráficos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    Map<String, int> conteoTipos = {};
    for (var anuncio in misAnuncios) {
      String rawTipo = anuncio.tipo.trim();
      if (rawTipo.isEmpty) rawTipo = "Otros";
      String tipoNormalizado =
          rawTipo[0].toUpperCase() + rawTipo.substring(1).toLowerCase();
      conteoTipos[tipoNormalizado] = (conteoTipos[tipoNormalizado] ?? 0) + 1;
    }

    final List<String> tipos = conteoTipos.keys.toList();
    final List<int> valores = conteoTipos.values.toList();
    double techoY = (valores.reduce(max) + 1).toDouble();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RENDIMIENTO GENERAL",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Análisis de distribución de activos",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 30),
          Container(
            height: 300,
            padding: const EdgeInsets.only(top: 20, right: 20, left: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: techoY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => primaryColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toInt().toString(),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < tipos.length) {
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              tipos[index],
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(tipos.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: valores[index].toDouble(),
                        color: primaryColor,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildTableDetail(conteoTipos),
        ],
      ),
    );
  }

  Widget _buildTableDetail(Map<String, int> conteoTipos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RESUMEN DE INVENTARIO",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(height: 30),
          ...conteoTipos.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${e.value} uds.",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
