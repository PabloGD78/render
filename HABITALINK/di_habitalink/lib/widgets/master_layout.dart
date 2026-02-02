import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MasterLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget sidebar;
  // 👇 1. AÑADIMOS ESTA VARIABLE PARA LOS BOTONES (PERFIL, ETC)
  final List<Widget>? actions; 

  const MasterLayout({
    super.key,
    required this.title,
    required this.body,
    required this.sidebar,
    this.actions, // 👈 2. LA AÑADIMOS AL CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    // Detectamos si es pantalla grande (Desktop) o pequeña (Móvil)
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.background,
      
      // --- APPBAR (SOLO PARA MÓVIL) ---
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 1,
              iconTheme: const IconThemeData(color: AppColors.primary),
              // 👇 3. AQUÍ PASAMOS LOS BOTONES AL APPBAR DE MÓVIL
              actions: actions, 
            ),

      // --- DRAWER (SOLO PARA MÓVIL) ---
      drawer: !isDesktop 
          ? Drawer(child: sidebar) 
          : null,

      // --- CUERPO PRINCIPAL ---
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SI ES DESKTOP, PONEMOS EL SIDEBAR FIJO A LA IZQUIERDA
          if (isDesktop) sidebar,

          // CONTENIDO
          Expanded(
            child: Column(
              children: [
                // HEADER TIPO WEB (SOLO DESKTOP)
                if (isDesktop) 
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        // 👇 4. AQUÍ PONEMOS LOS BOTONES EN MODO ESCRITORIO
                        if (actions != null) 
                          Row(children: actions!),
                      ],
                    ),
                  ),

                // EL CUERPO DE LA PÁGINA QUE LE PASAS
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}