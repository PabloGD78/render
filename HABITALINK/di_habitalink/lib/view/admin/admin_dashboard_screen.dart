import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- TUS IMPORTACIONES ---
import '../../theme/colors.dart';
import '../../widgets/stat_card.dart'; 
import '../../widgets/admin_sidebar.dart';
import '../../widgets/master_layout.dart'; 
import '/view/login_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _autoApproveProperties = false; 
  bool _isLoading = true;
  int _totalPropiedades = 0;
  int _totalUsuarios = 0; 
  List<dynamic> _actividadReciente = []; 

  // Ajusta esto: 'http://localhost:3000/api' para Web, 'http://10.0.2.2:3000/api' para Emulador Android
  final String _baseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final statsResponse = await http.get(Uri.parse('$_baseUrl/stats/admin'));

      if (statsResponse.statusCode == 200) {
        // 1. Decodificamos lo que llega del servidor
        dynamic responseRaw = json.decode(statsResponse.body);
        Map<String, dynamic> data;

        // 2. CORRECCIÓN ANTI-ERROR:
        // Si el servidor envía una lista [ {datos} ] en vez de un objeto { datos }, lo arreglamos aquí.
        if (responseRaw is List) {
          if (responseRaw.isNotEmpty) {
            data = responseRaw[0]; 
          } else {
            data = {}; 
          }
        } else {
          // Si ya es un mapa, perfecto
          data = responseRaw;
        }

        if (mounted) {
          setState(() {
            // 3. CONVERSIÓN SEGURA (String -> Int):
            // Usamos .toString() y luego int.tryParse para que NUNCA falle si llega un texto "5"
            _totalUsuarios = int.tryParse(data['totalUsuarios'].toString()) ?? 0;
            _totalPropiedades = int.tryParse(data['totalPropiedades'].toString()) ?? 0;
            
            // 4. Procesamos la lista de distribución
            if (data['distribucionUsuarios'] != null && data['distribucionUsuarios'] is List) {
              _actividadReciente = (data['distribucionUsuarios'] as List).map((item) {
                return {
                  "rol": item['rol'],
                  // Aquí también protegemos la conversión
                  "cantidad": int.tryParse(item['cantidad'].toString()) ?? 0, 
                };
              }).toList();
            } else {
              _actividadReciente = [];
            }
            
            _isLoading = false;
          });
        }
      } else {
        print("Error del servidor: ${statsResponse.body}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error cargando dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterLayout(
      title: "Panel de Administración",
      // El índice 0 le dice al Sidebar que marque "Dashboard"
      sidebar: const AdminSidebar(selectedIndex: 0),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, size: 30, color: AppColors.primary),
          onPressed: () => _showAdminProfileDialog(context),
        ),
        const SizedBox(width: 20),
      ],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Resumen General",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 20),

                // Tarjetas de estadísticas
                Wrap(
                  spacing: 20, 
                  runSpacing: 20,
                  children: [
                    StatCard(
                      title: "Usuarios Totales",
                      value: _totalUsuarios.toString(),
                      icon: Icons.people,
                      iconColor: Colors.blue,
                    ),
                    StatCard(
                      title: "Propiedades",
                      value: _totalPropiedades.toString(),
                      icon: Icons.home,
                      iconColor: Colors.orange,
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),
                
                const Text(
                  "Distribución de Usuarios", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)
                ),
                const SizedBox(height: 15),

                // Gráfico simplificado
                if (_actividadReciente.isEmpty)
                  const Text("No hay datos disponibles.")
                else
                  Column(
                    children: _actividadReciente.map((item) {
                      String rol = item['rol']?.toString() ?? 'Desconocido';
                      int cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
                      double porcentaje = _totalUsuarios > 0 ? (cantidad / _totalUsuarios) : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rol.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                Text("$cantidad usuarios", style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: porcentaje,
                                backgroundColor: Colors.grey.shade200,
                                color: AppColors.accent,
                                minHeight: 10,
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
    );
  }

  void _showAdminProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Perfil Admin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text("A", style: TextStyle(color: Colors.white)),
              ),
              title: Text("Super Admin"),
              subtitle: Text("admin@habitalink.com"),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Aprobación Automática"),
              activeColor: AppColors.primary,
              value: _autoApproveProperties,
              onChanged: (val) => setState(() => _autoApproveProperties = val),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400, 
                foregroundColor: Colors.white
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text("CERRAR SESIÓN"),
              onPressed: _handleLogout,
            )
          ],
        ),
      ),
    );
  }
}