// Elemento individual de contacto en el footer.
import 'package:flutter/material.dart';

class ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const ContactItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ],
    );
  }
}
