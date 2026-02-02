// Barra de búsqueda con filtro desplegable.
import 'package:flutter/material.dart';
import '../theme/colors.dart';

// ⭐ 1. AÑADIR PARÁMETROS AQUÍ ⭐
class SearchBarWidget extends StatefulWidget {
  final Color? accentColor;
  final Color? primaryColor;
  final bool isDense;
  final double borderRadius;

  const SearchBarWidget({
    super.key,
    // Hacemos los colores opcionales, si no se pasan, usaremos AppColors
    this.accentColor,
    this.primaryColor,
    // Usamos valores predeterminados para evitar errores si no se pasan
    this.isDense = false,
    this.borderRadius = 12.0,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  String selectedFilter = 'Vivienda';
  final List<String> filters = [
    'Vivienda',
    'Obra Nueva',
    'Oficina',
    'Garaje',
    'Localidad',
  ];

  @override
  Widget build(BuildContext context) {
    // 2. Usar los parámetros pasados o los colores predeterminados de AppColors
    final accent = widget.accentColor ?? AppColors.accent;
    final primary = widget.primaryColor ?? AppColors.primary;

    // 3. Usar el valor de borderRadius pasado por parámetro
    final radius = widget.borderRadius;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.5), // Usamos el parámetro
        borderRadius: BorderRadius.circular(radius), // Usamos el parámetro
        // Si quieres un borde, puedes usar primary:
        // border: Border.all(color: primary, width: 1.0),
      ),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFilter,
              icon: Icon(Icons.keyboard_arrow_down, color: primary, size: 26),
              dropdownColor: accent,
              style: TextStyle(color: primary, fontSize: 18),
              items: filters
                  .map(
                    (filter) =>
                        DropdownMenuItem(value: filter, child: Text(filter)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                  });
                }
              },
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Buscar vivienda, municipio...',
                border: InputBorder.none,
                isDense: widget.isDense, // Usamos el parámetro
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
          ),
          IconButton(
            onPressed: _doSearch,
            icon: Icon(Icons.search, color: primary, size: 28),
          ),
        ],
      ),
    );
  }

  void _doSearch() {
    final query = _controller.text.trim();
    Navigator.pushNamed(context, '/search_results',
        arguments: {'query': query, 'filter': selectedFilter});
  }
}
