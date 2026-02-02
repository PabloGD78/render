import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/colors.dart';
import '../../widgets/master_layout.dart';
import '../../widgets/admin_sidebar.dart';

class PropertiesView extends StatefulWidget {
  const PropertiesView({super.key});

  @override
  State<PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<PropertiesView> {
  List<dynamic> _properties = [];
  bool _isLoading = true;
  final String _baseUrl = "http://localhost:3000/api/admin";

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/properties'));

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _properties = data['properties'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error cargando propiedades: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _aprobarPropiedad(dynamic id) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/properties/$id/status'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": "disponible"}),
      );

      if (response.statusCode == 200) {
        _fetchProperties();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Propiedad aprobada")));
      }
    } catch (e) {
      print("Error aprobando: $e");
    }
  }

  Future<void> _confirmarBorrado(dynamic id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Propiedad"),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await http.delete(Uri.parse('$_baseUrl/properties/$id'));
                _fetchProperties();
              } catch (e) {
                print("Error borrando: $e");
              }
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterLayout(
      title: "Gestión de Propiedades",
      sidebar: const AdminSidebar(selectedIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: _properties.isEmpty
                        ? const Center(
                            child: Text("No hay propiedades registradas."),
                          )
                        : DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              AppColors.primary.withOpacity(0.1),
                            ),
                            columns: const [
                              DataColumn(label: Text("ID")),
                              DataColumn(label: Text("Inmueble")),
                              DataColumn(label: Text("Precio")),
                              DataColumn(label: Text("Estado")),
                              DataColumn(label: Text("Acciones")),
                            ],
                            rows: _properties.map((prop) {
                              final id = prop['id'];
                              // CORRECCIÓN: Usar 'nombre' para que coincida con el backend
                              final nombre = prop['nombre'] ?? "Sin nombre";
                              final tipo = prop['tipo'] ?? "Tipo N/A";
                              final precio = prop['precio'] ?? "0";
                              final estado =
                                  prop['estado']?.toString().toLowerCase() ??
                                  "pendiente";
                              final bool isPending = estado == 'pendiente';

                              return DataRow(
                                cells: [
                                  DataCell(Text("#$id")),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          tipo.toString().toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "$precio €",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? Colors.orange.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        estado.toUpperCase(),
                                        style: TextStyle(
                                          color: isPending
                                              ? Colors.orange.shade800
                                              : Colors.green.shade800,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (isPending)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                            onPressed: () =>
                                                _aprobarPropiedad(id),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _confirmarBorrado(id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
