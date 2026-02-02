// lib/widgets/property_card.dart (CÓDIGO FINAL Y ROBUSTO)
import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../theme/colors.dart';

class PropertyCard extends StatelessWidget {
  final PropertySummary property;
  final VoidCallback? onDetailsPressed;
  final double cardWidth;
  final double cardHeight;
  // Mantenemos la base URL en caso de que necesitemos concatenar la ruta relativa.
  final String serverBaseUrl = "http://localhost:3000";

  const PropertyCard({
    super.key,
    required this.property,
    required this.cardWidth,
    required this.cardHeight,
    this.onDetailsPressed,
  });

  @override
  Widget build(BuildContext context) {
  final String priceText = property.formattedPrice;

    // 🛠️ LÓGICA ROBUSTA PARA CONSTRUIR LA URL DE LA IMAGEN
    String finalImageUrl = '';

    // 1. Verificar si la URL existe y no está vacía
  if (property.imageUrl.isNotEmpty) {
      // Si la URL ya empieza con 'http(s)', asumimos que es completa (Caso Search Results)
      if (property.imageUrl.startsWith('http') ||
          property.imageUrl.startsWith('https')) {
        finalImageUrl = property.imageUrl;
      } else {
        // Si es una ruta relativa, necesitamos añadir la base URL (Caso Home Page)

        // Limpiar cualquier barra inicial redundante del path
        final String imagePath = property.imageUrl.startsWith('/')
            ? property.imageUrl.substring(1)
            : property.imageUrl;

        // Construir la URL completa
        finalImageUrl = '$serverBaseUrl/$imagePath';
      }

      // DEBUG: Imprime la URL final que se intenta cargar
      print('Intentando cargar imagen (FINAL ROBUSTO): $finalImageUrl');
    }

    // 2. Definición del Widget de la Imagen
    final Widget imageWidget = finalImageUrl.isEmpty
        ? Container(
            height: cardHeight * 0.5,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          )
        : Image.network(
            finalImageUrl,
            fit: BoxFit.cover,
            width: cardWidth,
            height: cardHeight * 0.5,
            // Usamos el errorBuilder para ver si la imagen falla por 404/CORS
            errorBuilder: (context, error, stackTrace) {
              // Eliminar este print una vez resuelto el problema
              print('⚠️ Error de carga de imagen para URL: $finalImageUrl');
              return Container(
                height: cardHeight * 0.5,
                color: Colors.red[100], // Fondo rojo para indicar fallo
                alignment: Alignment.center,
                child: const Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red,
                ),
              );
            },
          );

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        // Formato Vertical para el Carrusel de HomePage
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ Área de la Imagen
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: cardHeight * 0.5,
              width: double.infinity,
              child: Center(
                child:
                    imageWidget, // Usamos el widget dinámico (placeholder o Image.network)
              ),
            ),
          ),

          // 📝 Contenido de la tarjeta
          Expanded(
            // Usamos Expanded para que el contenido se ajuste si la altura es variable
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.details, // "X habs - Y baños - Z m2"
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(), // Empuja el botón hacia abajo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onDetailsPressed,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Row(
                          children: [
                            Text(
                              'más detalles',
                              style: TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
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
