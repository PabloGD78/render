// Item del menú de navegación en la barra superior.
import 'package:flutter/material.dart';

class NavMenuItem extends StatelessWidget {
  final String title;
  const NavMenuItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }
}
