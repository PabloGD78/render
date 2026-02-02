import 'package:flutter/material.dart';
import '../theme/colors.dart'; 

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ HEMOS QUITADO EL EXPANDED. Ahora usamos un Container con un ancho máximo.
    return Container(
      width: 200, // Le damos un ancho fijo para que se vea bien en el Wrap
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      padding: const EdgeInsets.all(20), // Cambiado por 20 si AppColors.kPadding te da error
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border(left: BorderSide(color: iconColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Importante: ajustarse al contenido
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value, 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)
          ),
          const SizedBox(height: 4),
          Text(
            title, 
            style: const TextStyle(color: Colors.grey, fontSize: 13), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }
}