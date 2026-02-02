import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/admin_service.dart';
import '../../widgets/master_layout.dart';
import '../../widgets/admin_sidebar.dart';

class ParticularesView extends StatefulWidget {
  const ParticularesView({super.key});

  @override
  State<ParticularesView> createState() => _ParticularesViewState();
}

class _ParticularesViewState extends State<ParticularesView> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final allUsers = await _adminService.getUsers();
      if (mounted) {
        setState(() {
          _users = allUsers
              .where((u) => u['tipo'].toString().toLowerCase() == 'particular')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmarBorrado(String id, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Particular"),
        content: const Text(
          "¿Seguro que quieres borrar este usuario particular?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _adminService.deleteUser(id);
              setState(() {
                _users.removeAt(index);
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Usuario eliminado correctamente"),
                  ),
                );
              }
            },
            child: const Text("Borrar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterLayout(
      title: "Gestión de Particulares",
      sidebar: const AdminSidebar(selectedIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            AppColors.primary.withOpacity(0.1),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                "Particular",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Correo",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Teléfono",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Estado",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Acciones",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: _users.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> user = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        radius: 15,
                                        child: Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "${user['nombre']} ${user['apellidos']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(user['correo'] ?? "")),
                                DataCell(Text(user['tlf'] ?? "---")),
                                DataCell(_buildStatusBadge("Activo")),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmarBorrado(
                                      user['id'].toString(),
                                      index,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
