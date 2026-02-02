import 'package:flutter/material.dart';
import '../theme/colors.dart';

// --- IMPORTACIONES DE TODAS LAS PANTALLAS ---
// Asegúrate de que estas rutas coincidan con tus carpetas
import '/view/admin/admin_dashboard_screen.dart'; // Case 0
import '/view/admin/professionals_view.dart';     // Case 1
import '/view/admin/particulares_view.dart';      // Case 2
import '/view/admin/clients_view.dart';           // Case 3 (Compradores)
import '/view/admin/properties_view.dart';        // Case 4
// -------------------------------------------

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          children: [
            // LOGO
            Container(
              height: 120,
              padding: const EdgeInsets.all(20),
              child: Image.asset("assets/logo/LogoSinFondo.png", fit: BoxFit.contain),
            ),
            const Divider(height: 1),
            
            // MENU
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(context, 0, "Dashboard", Icons.dashboard),
                  _buildMenuItem(context, 1, "Profesionales", Icons.business),
                  _buildMenuItem(context, 2, "Particulares", Icons.person),
                  _buildMenuItem(context, 3, "Clientes (Comp)", Icons.people),
                  _buildMenuItem(context, 4, "Propiedades", Icons.home_work),
                  const Divider(),
                  _buildMenuItem(context, 5, "Cerrar Sesión", Icons.logout),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, int index, String title, IconData icon) {
    bool isSelected = index == selectedIndex;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      onTap: () {
        // Evita recargar si ya estás en esa pantalla
        if (index == selectedIndex) return;

        Widget nextPage;

        // --- SISTEMA DE NAVEGACIÓN ---
        switch (index) {
          case 0:
            nextPage = const AdminDashboardScreen();
            break;
          case 1:
            nextPage = const ProfessionalsView(); // Abre la vista de profesionales
            break;
          case 2:
            nextPage = const ParticularesView(); // Abre la vista de particulares
            break;
          case 3:
            nextPage = const ClientsView();      // Abre la vista de compradores
            break;
          case 4:
            nextPage = const PropertiesView();   // Abre la vista de propiedades
            break;
            
          default:
            // Opción por defecto para botones sin pantalla (como cerrar sesión si se maneja aparte)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('La opción "$title" aún no está conectada.')),
            );
            return;
        }

        // Navegar a la pantalla seleccionada
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      },
    );
  }
}